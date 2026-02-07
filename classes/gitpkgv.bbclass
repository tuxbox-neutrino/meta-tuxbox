# gitpkgv.bbclass provides GITPKGV and GITPKGVTAG for PKGV.
#
# - GITPKGV:    <commit-count>+<short-rev>
# - GITPKGVTAG: <tag>-<prefix><commit-count>+<short-rev>
#
# This class is intended for PKGV usage only.
#
# Additional controls:
# - GITPKGV_PREFIX: prefix used by GITPKGVTAG (default: "git")
# - GITPKGV_TAG_REGEXP: regexp used to normalize git describe output
# - GITPKGVTAG_NO_WARN_ON_NO_TAG: set to "1" to suppress no-tag warnings
# - SRCPV_WORKSPACE: workspace fallback token (default: "999")

GITPKGV = "${@get_git_pkgv(d, False)}"
GITPKGVTAG = "${@get_git_pkgv(d, True)}"

GITPKGV_TAG_REGEXP ??= "(\d.*)-(.*)-g(.*)"
GITPKGV_PREFIX ??= "git"
GITPKGVTAG_NO_WARN_ON_NO_TAG ?= "0"
SRCPV_WORKSPACE ?= "999"

def gitpkgv_drop_tag_prefix(d, version):
    import re

    if not version:
        return version

    if version.lower().startswith("ver"):
        version = version[3:]
    if version and version[0].lower() == "v":
        version = version[1:]

    m = re.match(d.getVar("GITPKGV_TAG_REGEXP"), version)
    if m:
        return m.groups()[0]

    return version

def _gitpkgv_workspace_value(d):
    workspace_tag = d.getVar("SRCPV_WORKSPACE") or "999"
    srcpv = d.getVar("SRCPV")

    if srcpv and (srcpv == "999" or srcpv == workspace_tag):
        return workspace_tag

    return None

def _gitpkgv_tag_fallback(d, commits, rev_short):
    prefix = d.getVar("GITPKGV_PREFIX") or "git"
    return "0.0-%s%s+%s" % (prefix, commits, rev_short)

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
                    prefix = d.getVar("GITPKGV_PREFIX") or "git"
                    try:
                        output = bb.fetch2.runfetchcmd(
                            "git --git-dir=%(repodir)s describe %(rev)s --tags 2>/dev/null"
                            % vars,
                            d,
                            quiet=True,
                        ).strip()
                        tag = gitpkgv_drop_tag_prefix(d, output)
                        ver = "%s-%s%s+%s" % (tag, prefix, commits, rev_short)
                    except Exception:
                        if d.getVar("GITPKGVTAG_NO_WARN_ON_NO_TAG") != "1":
                            bb.warn(
                                "Missing Git tags, falling back to generated GITPKGVTAG value."
                            )
                        ver = _gitpkgv_tag_fallback(d, commits, rev_short)
                else:
                    ver = "%s+%s" % (commits, rev_short)

                format = format.replace(name, ver)

    if found:
        return format

    return d.getVar("SRCPV_WORKSPACE") or "999"
