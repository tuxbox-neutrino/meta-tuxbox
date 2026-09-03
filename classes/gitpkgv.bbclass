# gitpkgv.bbclass provides GITPKGV and GITPKGVTAG for PKGV.
#
# - GITPKGV:    <commit-count>+<short-rev>
# - GITPKGVTAG: <tag>-<prefix><commit-count>+<short-rev>
#
# This class is intended for PKGV usage only.
#
# Additional controls:
# - GITPKGV_PREFIX: prefix used by GITPKGVTAG (default: "-git")
# - GITPKGV_TAG_REGEXP: regexp used to normalize git describe output
# - GITPKGVTAG_STYLE: tag formatting mode for GITPKGVTAG (default: "count")
#   - "count":   <tag><prefix><commit-count>+<short-rev>
#   - "count-short": <tag><prefix><commits-since-tag>
#   - "exact":   exact tag only (fallback to generated value when not on tag)
#   - "describe": output from git describe normalized to package-safe syntax
# - GITPKGVTAG_NO_WARN_ON_NO_TAG: set to "1" to suppress no-tag warnings
# - GITPKGVTAG_PRIMARY: name of the SRC_URI git source to use for tag
#   resolution (default: unset, all sources are checked).  When set,
#   only the named source attempts git describe; all other sources
#   fall back to simple commits+rev without warnings.
# - SRCPV_WORKSPACE: workspace fallback token (default: "999")
#
# Workspace support:
# When EXTERNALSRC is set (devtool modify), externalsrc.bbclass sets
# SRCPV="999" and strips git URLs from SRC_URI.  If the EXTERNALSRC
# directory contains a .git repo, this class derives the real commit
# count and revision from the working tree so that workspace-built
# packages carry the same PKGV as a normal build of the same commit.

GITPKGV = "${@get_git_pkgv(d, False)}"
GITPKGVTAG = "${@get_git_pkgv(d, True)}"

GITPKGV_TAG_REGEXP ??= "(\d.*)-(.*)-g(.*)"
GITPKGV_PREFIX ??= "-git"
GITPKGVTAG_STYLE ??= "count"
GITPKGVTAG_NO_WARN_ON_NO_TAG ?= "0"
GITPKGVTAG_PRIMARY ??= ""
SRCPV_WORKSPACE ?= "999"

def _gitpkgv_strip_tag_prefix(version):
    if not version:
        return version

    if version.lower().startswith("ver"):
        version = version[3:]
    if version and version[0].lower() == "v":
        version = version[1:]

    return version

def gitpkgv_drop_tag_prefix(d, version):
    import re

    if not version:
        return version

    version = _gitpkgv_strip_tag_prefix(version)

    m = re.match(d.getVar("GITPKGV_TAG_REGEXP"), version)
    if m:
        return m.groups()[0]

    return version

def _gitpkgv_tag_style(d):
    import bb

    style = (d.getVar("GITPKGVTAG_STYLE") or "count").strip().lower()
    if style not in ("count", "count-short", "exact", "describe"):
        bb.warn(
            "Unsupported GITPKGVTAG_STYLE '%s', using default 'count'." % style
        )
        return "count"

    return style

def _gitpkgv_workspace_value(d):
    import os

    workspace_tag = d.getVar("SRCPV_WORKSPACE") or "999"
    srcpv = d.getVar("SRCPV")

    if srcpv and (srcpv == "999" or srcpv == workspace_tag):
        # If EXTERNALSRC points to a real git repo, skip the dummy value
        # and let get_git_pkgv derive a real version from the working tree.
        externalsrc = d.getVar("EXTERNALSRC")
        if externalsrc and os.path.exists(os.path.join(externalsrc, ".git")):
            return None
        return workspace_tag

    return None

def _gitpkgv_tag_fallback(d, commits, rev_short):
    prefix = d.getVar("GITPKGV_PREFIX") or "-git"
    return "0.0%s%s+%s" % (prefix, commits, rev_short)

def _gitpkgv_repo_has_tags(d, vars):
    import bb

    try:
        refs = bb.fetch2.runfetchcmd(
            "git --git-dir=%(repodir)s for-each-ref --count=1 --format='%%(refname)' refs/tags 2>/dev/null"
            % vars,
            d,
            quiet=True,
        ).strip()
        return bool(refs)
    except Exception:
        return False

def _gitpkgv_rev_available(d, vars):
    """True when the revision exists in the local mirror.

    AUTOREV resolves against the remote at parse time while the mirror can
    still be at an older state, so git describe fails on a revision that is
    simply not fetched yet.  That is transient -- the value is recomputed
    after do_fetch -- and must not be reported as a missing-tag condition.
    """
    import bb

    try:
        bb.fetch2.runfetchcmd(
            "git --git-dir=%(repodir)s cat-file -e %(rev)s^{commit} 2>/dev/null" % vars,
            d,
            quiet=True,
        )
        return True
    except Exception:
        return False

def _gitpkgv_from_externalsrc(d, use_tags):
    """Derive GITPKGV/GITPKGVTAG from an EXTERNALSRC git working tree.

    When devtool sets EXTERNALSRC, the normal fetcher-based path in
    get_git_pkgv() finds no git URLs (externalsrc strips them).  This
    helper reads commit count and rev directly from the working tree so
    that workspace-built packages carry the same version as a normal
    build of the same commit.
    """
    import os
    import subprocess

    externalsrc = d.getVar("EXTERNALSRC")
    if not externalsrc:
        return None

    gitdir = os.path.join(externalsrc, ".git")
    if not os.path.exists(gitdir):
        return None

    git_env = os.environ.copy()
    for var in tuple(git_env):
        if var.startswith("GIT_"):
            git_env.pop(var, None)

    try:
        commits = subprocess.check_output(
            ["git", "-C", externalsrc, "rev-list", "--count", "HEAD"],
            stderr=subprocess.DEVNULL,
            env=git_env,
            text=True,
        ).strip().lstrip("0") or "0"

        rev_short = subprocess.check_output(
            ["git", "-C", externalsrc, "rev-parse", "--short=7", "HEAD"],
            stderr=subprocess.DEVNULL,
            env=git_env,
            text=True,
        ).strip()
    except Exception:
        return None

    if not use_tags:
        return "%s+%s" % (commits, rev_short)

    prefix = d.getVar("GITPKGV_PREFIX") or "-git"
    style = _gitpkgv_tag_style(d)

    def describe(exact_match=False):
        cmd = ["git", "-C", externalsrc, "describe", "HEAD", "--tags"]
        if exact_match:
            cmd.append("--exact-match")
        return subprocess.check_output(
            cmd,
            stderr=subprocess.DEVNULL,
            env=git_env,
            text=True,
        ).strip()

    try:
        if style == "exact":
            output = describe(exact_match=True)
            return gitpkgv_drop_tag_prefix(d, output)
        elif style == "describe":
            output = describe(exact_match=False)
            return _gitpkgv_describe_version(d, output)
        elif style == "count-short":
            output = describe(exact_match=False)
            tag = gitpkgv_drop_tag_prefix(d, output)
            tag_count = _gitpkgv_describe_tag_count(output)
            if tag_count is None:
                tag_count = "0"
            return "%s%s%s" % (tag, prefix, tag_count)
        else:
            output = describe(exact_match=False)
            tag = gitpkgv_drop_tag_prefix(d, output)
            return "%s%s%s+%s" % (tag, prefix, commits, rev_short)
    except Exception:
        return _gitpkgv_tag_fallback(d, commits, rev_short)

def _gitpkgv_describe(d, vars, exact_match=False):
    import bb

    cmd = "git --git-dir=%(repodir)s describe %(rev)s --tags" % vars
    if exact_match:
        cmd += " --exact-match"

    return bb.fetch2.runfetchcmd(cmd + " 2>/dev/null", d, quiet=True).strip()

def _gitpkgv_describe_tag_count(output):
    """Extract the commit count since the last tag from git describe output.

    For 'v4.8.0-7-gfa3d998' returns '7'.  Returns None if the output
    does not match the expected describe format (e.g. exact tag match).
    """
    import re

    normalized = _gitpkgv_strip_tag_prefix(output)
    m = re.match(r"^(.*)-([0-9]+)-g([0-9a-fA-F]+)$", normalized)
    if m:
        return m.group(2)
    return None

def _gitpkgv_describe_version(d, output):
    import re

    normalized = _gitpkgv_strip_tag_prefix(output)
    m = re.match(r"^(.*)-([0-9]+)-g([0-9a-fA-F]+)$", normalized)
    if m:
        return "%s-%s+%s" % (m.group(1), m.group(2), m.group(3)[:7])

    return normalized

def get_git_pkgv(d, use_tags):
    import os
    import bb
    from shlex import quote

    workspace_value = _gitpkgv_workspace_value(d)
    if workspace_value is not None:
        return workspace_value

    # Prefer the real local git tree for devtool/EXTERNALSRC workspaces.  Some
    # recipes still expose fetcher metadata while building from EXTERNALSRC, but
    # package versions must describe the checked-out source tree.
    ver = _gitpkgv_from_externalsrc(d, use_tags)
    if ver is not None:
        return ver

    src_uri = (d.getVar("SRC_URI") or "").split()
    fetcher = bb.fetch2.Fetch(src_uri, d)
    ud = fetcher.ud

    format = d.getVar("SRCREV_FORMAT")
    if not format:
        names = []
        for url in ud.values():
            if url.type == "git" or url.type == "gitsm":
                names.extend(url.revisions.keys())
        if names:
            format = "_".join(names)
        else:
            format = "default"

    found = False

    for url in ud.values():
        if url.type == "git" or url.type == "gitsm":
            for name, rev in url.revisions.items():
                if not os.path.exists(url.localpath):
                    return d.getVar("SRCPV_WORKSPACE") or "999"

                found = True
                commits = "0"
                rev_str = str(rev)
                rev_short = rev_str[:7]
                vars = {
                    "repodir": quote(url.localpath),
                    "rev": quote(rev_str),
                }
                rev_file = os.path.join(url.localpath, "oe-gitpkgv_" + rev_str)

                if not os.path.exists(rev_file) or os.path.getsize(rev_file) == 0:
                    commits = bb.fetch2.runfetchcmd(
                        "git --git-dir=%(repodir)s rev-list %(rev)s -- 2>/dev/null | wc -l"
                        % vars,
                        d,
                        quiet=True,
                    ).strip().lstrip("0")
                    if commits != "":
                        oe.path.remove(rev_file, recurse=False)
                        with open(rev_file, "w", encoding="utf-8") as f:
                            f.write("%d\n" % int(commits))
                    else:
                        commits = "0"
                else:
                    with open(rev_file, "r", encoding="utf-8") as f:
                        commits = f.readline(128).strip() or "0"

                primary = (d.getVar("GITPKGVTAG_PRIMARY") or "").strip()
                is_primary = (not primary) or (name == primary)

                if use_tags and is_primary:
                    prefix = d.getVar("GITPKGV_PREFIX") or "-git"
                    style = _gitpkgv_tag_style(d)
                    try:
                        if style == "exact":
                            output = _gitpkgv_describe(d, vars, exact_match=True)
                            ver = gitpkgv_drop_tag_prefix(d, output)
                        elif style == "describe":
                            output = _gitpkgv_describe(d, vars, exact_match=False)
                            ver = _gitpkgv_describe_version(d, output)
                        elif style == "count-short":
                            output = _gitpkgv_describe(d, vars, exact_match=False)
                            tag = gitpkgv_drop_tag_prefix(d, output)
                            tag_count = _gitpkgv_describe_tag_count(output)
                            if tag_count is None:
                                tag_count = "0"
                            ver = "%s%s%s" % (tag, prefix, tag_count)
                        else:
                            output = _gitpkgv_describe(d, vars, exact_match=False)
                            tag = gitpkgv_drop_tag_prefix(d, output)
                            ver = "%s%s%s+%s" % (tag, prefix, commits, rev_short)
                    except Exception:
                        pn = d.getVar("PN") or "unknown"
                        if not _gitpkgv_rev_available(d, vars):
                            bb.note(
                                "%s: revision not in the local mirror yet; "
                                "GITPKGVTAG is recomputed after do_fetch" % pn
                            )
                        elif not _gitpkgv_repo_has_tags(d, vars):
                            if d.getVar("GITPKGVTAG_NO_WARN_ON_NO_TAG") != "1":
                                bb.warn(
                                    "%s: Missing Git tags, falling back to generated "
                                    "GITPKGVTAG value." % pn
                                )
                        else:
                            bb.warn(
                                "%s: git describe failed although the repository has "
                                "tags; PKGV falls back below the tag-based version." % pn
                            )
                        ver = _gitpkgv_tag_fallback(d, commits, rev_short)
                else:
                    ver = "%s+%s" % (commits, rev_short)

                format = format.replace(name, ver)

    if found:
        return format

    # Workspace/externalsrc fallback for recipes where fetcher metadata was
    # stripped after the initial workspace check.
    ver = _gitpkgv_from_externalsrc(d, use_tags)
    if ver is not None:
        return ver

    return d.getVar("SRCPV_WORKSPACE") or "999"
