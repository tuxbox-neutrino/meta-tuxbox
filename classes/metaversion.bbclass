# metaversion.bbclass
#
# Provides META_VERSION as commit count from a configurable git repository.
#
# Variables:
# - METAVERSION_GIT_PATH: explicit git working tree path (optional)
# - METAVERSION_GIT_REF:  git ref to count up to (default: HEAD)
# - METAVERSION_FALLBACK: value returned on lookup failure (default: 0)
# - METAVERSION_LAYER_BASENAME: BBLAYERS basename to resolve (optional)
# - METAVERSION_USE_COREBASE: if "1", use COREBASE when META_NAME is unset
#
# Default path resolution:
# 1) METAVERSION_GIT_PATH (if set)
# 2) BBLAYERS entry matching METAVERSION_LAYER_BASENAME or META_NAME
# 3) ${COREBASE}/${META_NAME} (legacy fallback when META_NAME is set)
# 4) ${COREBASE} (only when METAVERSION_USE_COREBASE = "1")

METAVERSION_GIT_PATH ?= ""
METAVERSION_GIT_REF ?= "HEAD"
METAVERSION_FALLBACK ?= "0"
METAVERSION_LAYER_BASENAME ??= ""
METAVERSION_USE_COREBASE ?= "0"

def _metaversion_repo_path(d):
    import os

    explicit_path = (d.getVar("METAVERSION_GIT_PATH") or "").strip()
    if explicit_path:
        return explicit_path

    meta_name = (d.getVar("META_NAME") or "").strip()
    layer_basename = (d.getVar("METAVERSION_LAYER_BASENAME") or meta_name).strip()
    if layer_basename:
        for layer in (d.getVar("BBLAYERS") or "").split():
            layer_path = os.path.normpath(layer)
            if os.path.basename(layer_path) == layer_basename:
                return layer_path

    corebase = (d.getVar("COREBASE") or "").strip()

    if not corebase:
        return ""

    if meta_name:
        return os.path.join(corebase, meta_name)

    if (d.getVar("METAVERSION_USE_COREBASE") or "0").strip() == "1":
        return corebase

    return ""

def _metaversion_git_env():
    import os

    env = os.environ.copy()
    for key in tuple(env):
        if key.startswith("GIT_"):
            env.pop(key, None)
    return env

def _metaversion_git_read(repo_path, *args):
    import subprocess

    if not repo_path:
        return ""

    try:
        return subprocess.check_output(
            ["git", "-C", repo_path, *args],
            stderr=subprocess.STDOUT,
            env=_metaversion_git_env(),
            text=True,
        ).strip()
    except Exception:
        return ""

def _metaversion_is_git_repo(repo_path):
    output = _metaversion_git_read(repo_path, "rev-parse", "--is-inside-work-tree")
    return output == "true"

def get_meta_repo_path(d):
    cached = d.getVar("_METAVERSION_REPO_PATH_CACHE")
    if cached is not None:
        return cached

    repo_path = _metaversion_repo_path(d)
    if repo_path and _metaversion_is_git_repo(repo_path):
        d.setVar("_METAVERSION_REPO_PATH_CACHE", repo_path)
        return repo_path

    d.setVar("_METAVERSION_REPO_PATH_CACHE", "")
    return ""

def get_meta_version(d):
    import subprocess
    import bb

    cached = d.getVar("_METAVERSION_CACHE")
    if cached is not None and cached != "":
        return cached

    fallback = (d.getVar("METAVERSION_FALLBACK") or "0").strip() or "0"
    configured_path = _metaversion_repo_path(d)
    repo_path = get_meta_repo_path(d)
    ref = (d.getVar("METAVERSION_GIT_REF") or "HEAD").strip() or "HEAD"

    if not configured_path:
        bb.note("metaversion: git path is empty, using fallback META_VERSION")
        d.setVar("_METAVERSION_CACHE", fallback)
        return fallback

    if not repo_path:
        bb.warn("metaversion: git path '%s' is not a git working tree, using fallback META_VERSION" % configured_path)
        d.setVar("_METAVERSION_CACHE", fallback)
        return fallback

    try:
        output = subprocess.check_output(
            ["git", "-C", repo_path, "rev-list", "--count", ref],
            stderr=subprocess.STDOUT,
            env=_metaversion_git_env(),
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

def get_meta_git_hash(d):
    cached = d.getVar("_METAVERSION_GIT_HASH_CACHE")
    if cached is not None:
        return cached

    repo_path = get_meta_repo_path(d)
    ref = (d.getVar("METAVERSION_GIT_REF") or "HEAD").strip() or "HEAD"
    value = _metaversion_git_read(repo_path, "rev-parse", "--short", ref)
    d.setVar("_METAVERSION_GIT_HASH_CACHE", value)
    return value

def get_meta_git_describe(d):
    cached = d.getVar("_METAVERSION_GIT_DESCRIBE_CACHE")
    if cached is not None:
        return cached

    repo_path = get_meta_repo_path(d)
    ref = (d.getVar("METAVERSION_GIT_REF") or "HEAD").strip() or "HEAD"
    if ref == "HEAD":
        value = _metaversion_git_read(repo_path, "describe", "--always", "--tags", "--dirty")
    else:
        value = _metaversion_git_read(repo_path, "describe", "--always", "--tags", ref)
    d.setVar("_METAVERSION_GIT_DESCRIBE_CACHE", value)
    return value

def get_meta_git_dirty(d):
    cached = d.getVar("_METAVERSION_GIT_DIRTY_CACHE")
    if cached is not None:
        return cached

    repo_path = get_meta_repo_path(d)
    if not repo_path:
        value = ""
    else:
        value = "1" if _metaversion_git_read(repo_path, "status", "--porcelain") else "0"
    d.setVar("_METAVERSION_GIT_DIRTY_CACHE", value)
    return value

META_VERSION ??= "${@get_meta_version(d)}"

# get_meta_version() memoizes into the datastore, so the variable references it
# records depend on whether the cache was already populated when the expansion
# happened. Cooker and worker hit that in different order and BitBake then
# reports a changed basehash on reparse for every task that sees IMAGE_VERSION.
# Hash the resolved commit count instead of the machinery that produces it: the
# value still changes with every layer commit, which is what images must react
# to, but it no longer depends on expansion order.
META_VERSION[vardepvalue] = "${META_VERSION}"
