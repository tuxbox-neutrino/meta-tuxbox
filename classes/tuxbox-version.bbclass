# Tuxbox image-version metadata
#
# Generates /etc/image-version during rootfs post-processing and creates
# /.version as compatibility symlink.

# Build stamp used in image-version metadata.
TUXBOX_IMAGEBUILD ??= "${DATETIME}"
TUXBOX_IMAGEBUILD[vardepsexclude] = "DATETIME"

# Optional metadata overrides for /etc/image-version.
TUXBOX_IMAGE_DESCRIPTION ?= "${IMAGE_NAME}"
TUXBOX_IMAGE_DIR ?= "${@d.getVar('IMAGEDIR') or d.getVar('MACHINE') or ''}"
TUXBOX_IMAGE_UPDATE_URL ?= "${@d.getVar('IMAGE_LOCATION_URL') or ''}"
TUXBOX_IMAGE_UPDATE_INFO_FILE ?= "imageversion"
TUXBOX_IMAGE_FILE_NAME ?= "${IMAGE_NAME}_usb.zip"
TUXBOX_VERSION_STAMP ?= "${TUXBOX_IMAGEBUILD}"

# Optional explicit git repository for describe/hash resolution.
# Default auto-detection:
# 1) parent of COREBASE (tuxbox orchestrator checkout)
# 2) COREBASE itself
TUXBOX_VERSION_GIT_PATH ?= ""
TUXBOX_VERSION_GIT_REF ?= "HEAD"

ROOTFS_POSTPROCESS_COMMAND += "tuxbox_generate_version_info; "

python tuxbox_generate_version_info() {
    import os
    import subprocess
    import bb

    def _safe(value, default=""):
        if value is None:
            return default
        value = str(value).strip()
        return value if value else default

    def _repo_is_git(path):
        return os.path.isdir(os.path.join(path, ".git"))

    def _detect_git_repo():
        explicit = _safe(d.getVar("TUXBOX_VERSION_GIT_PATH"))
        if explicit and _repo_is_git(explicit):
            return explicit

        corebase = _safe(d.getVar("COREBASE"))
        if not corebase:
            return ""

        parent = os.path.dirname(corebase)
        if parent and _repo_is_git(parent):
            return parent

        if _repo_is_git(corebase):
            return corebase

        return ""

    def _git_read(repo_path, *args):
        if not repo_path:
            return ""
        try:
            return subprocess.check_output(
                ["git", "-C", repo_path, *args],
                stderr=subprocess.DEVNULL,
                text=True,
            ).strip()
        except Exception:
            return ""

    rootfs = _safe(d.getVar("IMAGE_ROOTFS"))
    if not rootfs:
        bb.warn("tuxbox-version: IMAGE_ROOTFS is empty, skipping image-version generation")
        return

    version_file = os.path.join(rootfs, "etc", "image-version")
    os.makedirs(os.path.dirname(version_file), exist_ok=True)

    image_name = _safe(d.getVar("IMAGE_NAME"))
    image_basename = _safe(d.getVar("IMAGE_BASENAME"), image_name)
    machine = _safe(d.getVar("MACHINE"))
    image_dir = _safe(d.getVar("TUXBOX_IMAGE_DIR"), machine)
    distro = _safe(d.getVar("DISTRO"))
    distro_name = _safe(d.getVar("DISTRO_NAME"))
    distro_version = _safe(d.getVar("DISTRO_VERSION"))
    distro_codename = _safe(d.getVar("DISTRO_CODENAME"))
    image_version = _safe(d.getVar("IMAGE_VERSION"), distro_version)
    version_stamp = _safe(d.getVar("TUXBOX_VERSION_STAMP"), image_version)
    image_description = _safe(d.getVar("TUXBOX_IMAGE_DESCRIPTION"), image_name)
    image_update_url = _safe(d.getVar("TUXBOX_IMAGE_UPDATE_URL"))
    image_update_info_file = _safe(d.getVar("TUXBOX_IMAGE_UPDATE_INFO_FILE"), "imageversion")
    image_file_name = _safe(d.getVar("TUXBOX_IMAGE_FILE_NAME"))
    creator = _safe(d.getVar("CREATOR"), "Tuxbox-OS Builder")
    build_date = _safe(d.getVar("TUXBOX_IMAGEBUILD"))

    git_repo = _detect_git_repo()
    git_ref = _safe(d.getVar("TUXBOX_VERSION_GIT_REF"), "HEAD")
    git_hash = _git_read(git_repo, "rev-parse", "--short", git_ref)
    # "--dirty" is only valid without an explicit commit-ish.
    if git_ref == "HEAD":
        git_describe = _git_read(git_repo, "describe", "--always", "--tags", "--dirty")
    else:
        git_describe = _git_read(git_repo, "describe", "--always", "--tags", git_ref)

    lines = [
        ("distro", distro),
        ("distro_name", distro_name),
        ("distro_version", distro_version),
        ("distro_codename", distro_codename),
        ("machine", machine),
        ("box_model", machine),
        ("imagedir", image_dir),
        ("version", version_stamp),
        ("imagedescription", image_description),
        ("image_name", image_name),
        ("image_version", image_version),
        ("image_file_name", image_file_name),
        ("image_update_url", image_update_url),
        ("image_update_info_file", image_update_info_file),
        ("build_date", build_date),
        ("creator", creator),
        # Compatibility keys expected by older scripts/plugins
        ("builddate", build_date),
        ("imagename", image_basename),
        ("imageversion", distro_version),
    ]

    if git_hash:
        lines.append(("git_hash", git_hash))
    if git_describe:
        lines.append(("describe", git_describe))

    with open(version_file, "w", encoding="utf-8") as f:
        for key, value in lines:
            f.write("%s=%s\n" % (key, value))

    os.chmod(version_file, 0o644)

    # Keep compatibility with components reading /.version directly.
    root_version = os.path.join(rootfs, ".version")
    if os.path.lexists(root_version):
        os.unlink(root_version)
    os.symlink("/etc/image-version", root_version)

    bb.note("Generated %s" % version_file)
}
