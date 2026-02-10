# metaversion.bbclass
#
# Provides META_VERSION as commit count from a configurable git repository.
#
# Variables:
# - METAVERSION_GIT_PATH: explicit git working tree path (optional)
# - METAVERSION_GIT_REF:  git ref to count up to (default: HEAD)
# - METAVERSION_FALLBACK: value returned on lookup failure (default: 0)
# - METAVERSION_USE_COREBASE: if "1", use COREBASE when META_NAME is unset
#
# Default path resolution:
# 1) METAVERSION_GIT_PATH (if set)
# 2) ${COREBASE}/${META_NAME} (if META_NAME is set)
# 3) ${COREBASE} (only when METAVERSION_USE_COREBASE = "1")

METAVERSION_GIT_PATH ?= ""
METAVERSION_GIT_REF ?= "HEAD"
METAVERSION_FALLBACK ?= "0"
METAVERSION_USE_COREBASE ?= "0"

def _metaversion_repo_path(d):
    import os

    explicit_path = (d.getVar("METAVERSION_GIT_PATH") or "").strip()
    if explicit_path:
        return explicit_path

    corebase = (d.getVar("COREBASE") or "").strip()
    meta_name = (d.getVar("META_NAME") or "").strip()

    if not corebase:
        return ""

    if meta_name:
        return os.path.join(corebase, meta_name)

    if (d.getVar("METAVERSION_USE_COREBASE") or "0").strip() == "1":
        return corebase

    return ""

def get_meta_version(d):
    import os
    import subprocess
    import bb

    cached = d.getVar("_METAVERSION_CACHE")
    if cached is not None and cached != "":
        return cached

    fallback = (d.getVar("METAVERSION_FALLBACK") or "0").strip() or "0"
    repo_path = _metaversion_repo_path(d)
    ref = (d.getVar("METAVERSION_GIT_REF") or "HEAD").strip() or "HEAD"

    if not repo_path:
        bb.note("metaversion: git path is empty, using fallback META_VERSION")
        d.setVar("_METAVERSION_CACHE", fallback)
        return fallback

    if not os.path.isdir(repo_path):
        bb.warn("metaversion: git path '%s' does not exist, using fallback META_VERSION" % repo_path)
        d.setVar("_METAVERSION_CACHE", fallback)
        return fallback

    try:
        output = subprocess.check_output(
            ["git", "-C", repo_path, "rev-list", "--count", ref],
            stderr=subprocess.STDOUT,
            text=True,
        ).strip()
        version = output or fallback
    except subprocess.CalledProcessError as e:
        details = (e.output or "").strip()
        if details:
            bb.warn("metaversion: git rev-list failed for '%s': %s" % (repo_path, details))
        else:
            bb.warn("metaversion: git rev-list failed for '%s'" % repo_path)
        version = fallback
    except FileNotFoundError:
        bb.warn("metaversion: git not found in PATH, using fallback META_VERSION")
        version = fallback

    d.setVar("_METAVERSION_CACHE", version)
    return version

META_VERSION ??= "${@get_meta_version(d)}"
