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
#   - "count-short": <tag><prefix><commit-count>
#   - "exact":   exact tag only (fallback to generated value when not on tag)
#   - "describe": output from git describe normalized to package-safe syntax
# - GITPKGVTAG_NO_WARN_ON_NO_TAG: set to "1" to suppress no-tag warnings
# - SRCPV_WORKSPACE: workspace fallback token (default: "999")

GITPKGV = "${@get_git_pkgv(d, False)}"
GITPKGVTAG = "${@get_git_pkgv(d, True)}"

GITPKGV_TAG_REGEXP ??= "(\d.*)-(.*)-g(.*)"
GITPKGV_PREFIX ??= "-git"
GITPKGVTAG_STYLE ??= "count"
GITPKGVTAG_NO_WARN_ON_NO_TAG ?= "0"
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
    workspace_tag = d.getVar("SRCPV_WORKSPACE") or "999"
    srcpv = d.getVar("SRCPV")

    if srcpv and (srcpv == "999" or srcpv == workspace_tag):
        return workspace_tag

    return None

def _gitpkgv_tag_fallback(d, commits, rev_short):
    prefix = d.getVar("GITPKGV_PREFIX") or "-git"
    return "0.0%s%s+%s" % (prefix, commits, rev_short)

def _gitpkgv_repo_has_tags(d, vars):
    import bb

    try:
        refs = bb.fetch2.runfetchcmd(
            "git --git-dir=%(repodir)s for-each-ref --count=1 --format='%(refname)' refs/tags 2>/dev/null"
            % vars,
            d,
            quiet=True,
        ).strip()
        return bool(refs)
    except Exception:
        return False

def _gitpkgv_describe(d, vars, exact_match=False):
    import bb

    cmd = "git --git-dir=%(repodir)s describe %(rev)s --tags" % vars
    if exact_match:
        cmd += " --exact-match"

    return bb.fetch2.runfetchcmd(cmd + " 2>/dev/null", d, quiet=True).strip()

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

                if use_tags:
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
                            ver = "%s%s%s" % (tag, prefix, commits)
                        else:
                            output = _gitpkgv_describe(d, vars, exact_match=False)
                            tag = gitpkgv_drop_tag_prefix(d, output)
                            ver = "%s%s%s+%s" % (tag, prefix, commits, rev_short)
                    except Exception:
                        has_tags = _gitpkgv_repo_has_tags(d, vars)
                        if (not has_tags) and d.getVar("GITPKGVTAG_NO_WARN_ON_NO_TAG") != "1":
                            bb.warn(
                                "Missing Git tags, falling back to generated GITPKGVTAG value."
                            )
                        elif has_tags:
                            bb.note(
                                "git describe failed; using generated GITPKGVTAG fallback for %s"
                                % (d.getVar("PN") or "unknown")
                            )
                        ver = _gitpkgv_tag_fallback(d, commits, rev_short)
                else:
                    ver = "%s+%s" % (commits, rev_short)

                format = format.replace(name, ver)

    if found:
        return format

    return d.getVar("SRCPV_WORKSPACE") or "999"
