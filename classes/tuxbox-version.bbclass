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
TUXBOX_IMAGE_CHANNEL ?= "${DISTRO_TYPE}"
TUXBOX_IMAGE_UPDATE_BASE_URL ?= "${@d.getVar('IMAGE_LOCATION_URL') or d.getVar('DISTRO_FEED_URI') or ''}"
TUXBOX_IMAGE_UPDATE_URL ?= ""
TUXBOX_IMAGE_UPDATE_INFO_FILE ?= "imageversion"
TUXBOX_IMAGE_FILE_SUFFIX ?= "${@'multi' if bb.utils.contains('MACHINE_FEATURES', 'fastboot', True, False, d) else 'usb'}"
TUXBOX_IMAGE_FILE_NAME ?= "${IMAGE_NAME}_${TUXBOX_IMAGE_FILE_SUFFIX}.zip"
TUXBOX_IMAGE_MANIFEST_FILE ?= "manifest.json"
TUXBOX_IMAGE_DISCOVERY_API_URL ?= ""
TUXBOX_VERSION_STAMP ?= "${TUXBOX_IMAGEBUILD}"
# Compatibility toggle for /.version symlink target:
# 0 -> /etc/image-version (legacy)
# 1 -> /etc/os-release
TUXBOX_VERSION_LINK_OS_RELEASE ?= "0"
TUXBOX_VERSION_LEGACY_LINK_TARGET ?= "/etc/image-version"
TUXBOX_FEED_WRITE_METADATA ?= "1"
TUXBOX_FEED_WRITE_SIDECARS ?= "1"

# Optional explicit git repository for describe/hash resolution.
# Default auto-detection:
# 1) parent of COREBASE (tuxbox orchestrator checkout)
# 2) COREBASE itself
TUXBOX_VERSION_GIT_PATH ?= ""
TUXBOX_VERSION_GIT_REF ?= "HEAD"

ROOTFS_POSTPROCESS_COMMAND += "tuxbox_generate_version_info; "
IMAGE_POSTPROCESS_COMMAND += "tuxbox_generate_feed_metadata; "

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
    image_update_base_url = _safe(d.getVar("TUXBOX_IMAGE_UPDATE_BASE_URL"))
    image_update_info_file = _safe(d.getVar("TUXBOX_IMAGE_UPDATE_INFO_FILE"), "imageversion")
    image_file_name = _safe(d.getVar("TUXBOX_IMAGE_FILE_NAME"))
    image_manifest_file = _safe(d.getVar("TUXBOX_IMAGE_MANIFEST_FILE"), "manifest.json")
    image_discovery_api_url = _safe(d.getVar("TUXBOX_IMAGE_DISCOVERY_API_URL"))
    image_service_key = _safe(d.getVar("TUXBOX_SERVICE_KEY"))
    channel = _safe(d.getVar("TUXBOX_IMAGE_CHANNEL"), "nightly")
    if channel not in ("release", "beta", "nightly"):
        channel = "nightly"
    flash_backend = _safe(d.getVar("TUXBOX_FLASH_BACKEND"), "script")
    creator = _safe(d.getVar("CREATOR"), "Tuxbox-OS Builder")
    build_date = _safe(d.getVar("TUXBOX_IMAGEBUILD"))

    if not image_update_url and image_update_base_url:
        image_update_url = "%s/%s/%s" % (
            image_update_base_url.rstrip("/"),
            channel.strip("/"),
            image_dir.strip("/"),
        )

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
        ("flash_backend", flash_backend),
        ("channel", channel),
        ("image_update_url", image_update_url),
        ("image_update_info_file", image_update_info_file),
        ("image_manifest_file", image_manifest_file),
        ("image_discovery_api_url", image_discovery_api_url),
        ("image_service_key", image_service_key),
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
    link_to_os_release = _safe(d.getVar("TUXBOX_VERSION_LINK_OS_RELEASE"), "0").lower()
    use_os_release_link = link_to_os_release in ("1", "y", "yes", "true", "on")
    legacy_link_target = _safe(
        d.getVar("TUXBOX_VERSION_LEGACY_LINK_TARGET"),
        "/etc/image-version",
    )
    root_link_target = "/etc/os-release" if use_os_release_link else legacy_link_target
    if use_os_release_link:
        os_release_path = os.path.join(rootfs, "etc", "os-release")
        if not os.path.exists(os_release_path):
            bb.warn(
                "tuxbox-version: /etc/os-release missing in rootfs, "
                "falling back to %s" % legacy_link_target
            )
            root_link_target = legacy_link_target

    root_version = os.path.join(rootfs, ".version")
    if os.path.lexists(root_version):
        os.unlink(root_version)
    os.symlink(root_link_target, root_version)

    bb.note("Generated %s" % version_file)
}

python tuxbox_generate_feed_metadata() {
    import hashlib
    import json
    import os
    import subprocess
    import bb

    def _safe(value, default=""):
        if value is None:
            return default
        value = str(value).strip()
        return value if value else default

    def _enabled(var_name, default="1"):
        value = _safe(d.getVar(var_name), default).lower()
        return value in ("1", "y", "yes", "true", "on")

    def _repo_is_git(path):
        return bool(path) and os.path.isdir(os.path.join(path, ".git"))

    def _detect_git_repo():
        explicit = _safe(d.getVar("TUXBOX_VERSION_GIT_PATH"))
        if _repo_is_git(explicit):
            return explicit

        corebase = _safe(d.getVar("COREBASE"))
        if not corebase:
            return ""

        parent = os.path.dirname(corebase)
        if _repo_is_git(parent):
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

    def _sha256sum(path):
        digest = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def _md5sum(path):
        digest = hashlib.md5()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    if not _enabled("TUXBOX_FEED_WRITE_METADATA", "1"):
        bb.note("tuxbox-version: feed metadata generation disabled")
        return

    deploy_dir = _safe(d.getVar("DEPLOY_DIR_IMAGE"))
    if not deploy_dir or not os.path.isdir(deploy_dir):
        bb.warn("tuxbox-version: DEPLOY_DIR_IMAGE missing, skipping feed metadata generation")
        return

    image_name = _safe(d.getVar("IMAGE_NAME"))
    if not image_name:
        bb.warn("tuxbox-version: IMAGE_NAME empty, skipping feed metadata generation")
        return

    machine = _safe(d.getVar("MACHINE"))
    image_dir = _safe(d.getVar("TUXBOX_IMAGE_DIR"), machine)
    distro = _safe(d.getVar("DISTRO"))
    distro_version = _safe(d.getVar("DISTRO_VERSION"))
    image_version = _safe(d.getVar("IMAGE_VERSION"), distro_version)
    version_stamp = _safe(d.getVar("TUXBOX_VERSION_STAMP"), image_version)
    build_date = _safe(d.getVar("TUXBOX_IMAGEBUILD"))
    flash_backend = _safe(d.getVar("TUXBOX_FLASH_BACKEND"), "script")
    channel = _safe(d.getVar("TUXBOX_IMAGE_CHANNEL"), "nightly")
    if channel not in ("release", "beta", "nightly"):
        channel = "nightly"
    image_description = _safe(d.getVar("TUXBOX_IMAGE_DESCRIPTION"), image_name)

    manifest_name = _safe(d.getVar("TUXBOX_IMAGE_MANIFEST_FILE"), "manifest.json")
    if "/" in manifest_name or ".." in manifest_name:
        bb.warn("tuxbox-version: invalid TUXBOX_IMAGE_MANIFEST_FILE '%s', using manifest.json" % manifest_name)
        manifest_name = "manifest.json"

    info_file_name = _safe(d.getVar("TUXBOX_IMAGE_UPDATE_INFO_FILE"), "imageversion")
    if "/" in info_file_name or ".." in info_file_name:
        bb.warn("tuxbox-version: invalid TUXBOX_IMAGE_UPDATE_INFO_FILE '%s', using imageversion" % info_file_name)
        info_file_name = "imageversion"

    requested_primary = _safe(d.getVar("TUXBOX_IMAGE_FILE_NAME"))
    candidate_names = []
    for name in (
        requested_primary,
        "%s_multi.zip" % image_name,
        "%s_usb.zip" % image_name,
    ):
        if name and name not in candidate_names:
            candidate_names.append(name)

    primary_path = ""
    primary_name = ""
    for name in candidate_names:
        path = os.path.join(deploy_dir, name)
        if os.path.isfile(path):
            primary_path = path
            primary_name = name
            break

    if not primary_path:
        bb.warn(
            "tuxbox-version: no primary archive found in %s (checked: %s)"
            % (deploy_dir, ", ".join(candidate_names))
        )
        return

    files = []
    include_names = [
        primary_name,
        "%s_recovery_emmc.zip" % image_name,
    ]

    write_sidecars = _enabled("TUXBOX_FEED_WRITE_SIDECARS", "1")
    for name in include_names:
        path = os.path.join(deploy_dir, name)
        if not os.path.isfile(path):
            continue

        sha256 = _sha256sum(path)
        md5 = _md5sum(path)
        size = os.path.getsize(path)
        files.append(
            {
                "name": name,
                "size": int(size),
                "sha256": sha256,
                "md5": md5,
            }
        )

        if write_sidecars:
            sidecar_path = path + ".sha256"
            with open(sidecar_path, "w", encoding="utf-8") as f:
                f.write("%s  %s\n" % (sha256, name))
            os.chmod(sidecar_path, 0o644)

            sidecar_md5_path = path + ".md5"
            with open(sidecar_md5_path, "w", encoding="utf-8") as f:
                f.write("%s  %s\n" % (md5, name))
            os.chmod(sidecar_md5_path, 0o644)

    if not files:
        bb.warn("tuxbox-version: no feed files selected, skipping manifest generation")
        return

    git_repo = _detect_git_repo()
    git_ref = _safe(d.getVar("TUXBOX_VERSION_GIT_REF"), "HEAD")
    git_hash = _git_read(git_repo, "rev-parse", "--short", git_ref)
    if git_ref == "HEAD":
        git_describe = _git_read(git_repo, "describe", "--always", "--tags", "--dirty")
    else:
        git_describe = _git_read(git_repo, "describe", "--always", "--tags", git_ref)

    manifest = {
        "schema_version": 1,
        "channel": channel,
        "distro": distro,
        "distro_version": distro_version,
        "machine": machine,
        "imagedir": image_dir,
        "image_name": image_name,
        "image_version": image_version,
        "version": version_stamp,
        "build_date": build_date,
        "flash_backend": flash_backend,
        "image_description": image_description,
        "files": files,
    }

    if git_hash:
        manifest["git_hash"] = git_hash
    if git_describe:
        manifest["describe"] = git_describe
        manifest["source_describe"] = git_describe

    marker_path = os.path.join(deploy_dir, info_file_name)
    with open(marker_path, "w", encoding="utf-8") as f:
        f.write("%s\n" % image_name)
    os.chmod(marker_path, 0o644)

    manifest_path = os.path.join(deploy_dir, manifest_name)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, sort_keys=True, ensure_ascii=False)
        f.write("\n")
    os.chmod(manifest_path, 0o644)

    if write_sidecars:
        manifest_sha = _sha256sum(manifest_path)
        manifest_sidecar = manifest_path + ".sha256"
        with open(manifest_sidecar, "w", encoding="utf-8") as f:
            f.write("%s  %s\n" % (manifest_sha, manifest_name))
        os.chmod(manifest_sidecar, 0o644)

    bb.note(
        "Generated feed metadata: %s, %s, %d file entries"
        % (marker_path, manifest_path, len(files))
    )
}
