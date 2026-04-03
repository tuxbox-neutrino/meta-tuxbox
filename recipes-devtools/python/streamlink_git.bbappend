# Use the Python-3.13-safe gitpkgv implementation for PKGV generation.
inherit gitpkgv

# Keep Streamlink license checksum in sync with upstream LICENSE updates.
LIC_FILES_CHKSUM = "file://LICENSE;md5=ca97af75b78809a5c401f63ead0f59f2"

# Mark this bbappend revision for feed updates.
PR:append = ".16"

# Override the gittag-based PKGV from oe-alliance streamlink recipe.
PKGV = "${GITPKGVTAG}"

# The upstream hard dependency on python3-shell is not needed for our launcher.
# Keep streamlink installable from feeds without dragging in an unnecessary split.
RDEPENDS:${PN}:remove = "${PYTHON_PN}-shell"
# OE python module runtime packages are mostly bytecode-only; ensure streamlink
# gets importable python sources for its module dependencies.
RDEPENDS:${PN}:append = " \
    ${PYTHON_PN}-src \
    ${PYTHON_PN}-certifi-src \
    ${PYTHON_PN}-chardet-src \
    ${PYTHON_PN}-futures3-src \
    ${PYTHON_PN}-idna-src \
    ${PYTHON_PN}-isodate-src \
    ${PYTHON_PN}-lxml-src \
    ${PYTHON_PN}-pycountry-src \
    ${PYTHON_PN}-pycryptodome-src \
    ${PYTHON_PN}-pysocks-src \
    ${PYTHON_PN}-requests-src \
    ${PYTHON_PN}-six-src \
    ${PYTHON_PN}-typing-extensions \
    ${PYTHON_PN}-typing-extensions-src \
    ${PYTHON_PN}-urllib3-src \
    ${PYTHON_PN}-websocket-client-src \
"

do_install:append() {
    # Ensure core streamlink python module is present. Upstream recipe's
    # setuptools output currently installs only streamlink_cli metadata.
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink
    if [ -d "${S}/src/streamlink" ]; then
        cp -a --no-preserve=ownership ${S}/src/streamlink/. ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/
    fi

    # We install from VCS sources, so streamlink/_version.py would try runtime
    # git metadata resolution via versioningit. Pin a static version instead.
    cat >${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/_version.py <<EOF
__version__ = "${PV}"
EOF

    # streamlink upstream expects urllib3>=2 export location.
    # Keep compatibility with urllib3 1.26 in kirkstone by falling back.
    if [ -f "${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/session/http.py" ]; then
        http_py="${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/session/http.py"
        awk '
            /^import urllib3.util.connection as urllib3_util_connection/ {
                print
                print ""
                print "if not hasattr(urllib3.util.url, \"_PERCENT_RE\") and hasattr(urllib3.util.url, \"PERCENT_RE\"):"
                print "    urllib3.util.url._PERCENT_RE = urllib3.util.url.PERCENT_RE  # type: ignore[attr-defined]"
                next
            }
            /^from urllib3.util import create_urllib3_context/ {
                print "try:"
                print "    from urllib3.util import create_urllib3_context  # type: ignore[attr-defined]"
                print "except ImportError:"
                print "    from urllib3.util.ssl_ import create_urllib3_context  # type: ignore[attr-defined]"
                next
            }
            { print }
        ' "${http_py}" > "${http_py}.new"
        mv "${http_py}.new" "${http_py}"
    fi

    # Older kirkstone python stack does not ship trio. Keep plugin loading
    # functional by providing a synchronous ProcessOutput fallback.
    if [ -f "${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/stream/ffmpegmux.py" ]; then
        mux_py="${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/stream/ffmpegmux.py"
        awk '
            /^from streamlink.utils.processoutput import ProcessOutput/ {
                print "try:"
                print "    from streamlink.utils.processoutput import ProcessOutput"
                print "except Exception:"
                print "    class ProcessOutput:"
                print "        def __init__(self, command, timeout=None, wait_terminate=2.0, stdin=subprocess.PIPE):"
                print "            self.command = command"
                print "            self.timeout = timeout"
                print "            self.wait_terminate = wait_terminate"
                print "            self.stdin = stdin"
                print ""
                print "        def run(self):"
                print "            proc = subprocess.Popen("
                print "                self.command,"
                print "                stdin=self.stdin,"
                print "                stdout=subprocess.PIPE,"
                print "                stderr=subprocess.PIPE,"
                print "                text=True,"
                print "            )"
                print "            try:"
                print "                out, err = proc.communicate(timeout=self.timeout)"
                print "            except subprocess.TimeoutExpired:"
                print "                proc.kill()"
                print "                return False"
                print ""
                print "            for idx, line in enumerate((out or \"\").splitlines()):"
                print "                res = self.onstdout(idx, line.strip())"
                print "                if res is not None:"
                print "                    return bool(res)"
                print ""
                print "            for idx, line in enumerate((err or \"\").splitlines()):"
                print "                res = self.onstderr(idx, line.strip())"
                print "                if res is not None:"
                print "                    return bool(res)"
                print ""
                print "            return self.onexit(proc.returncode)"
                print ""
                print "        def onexit(self, code):"
                print "            return code == 0"
                print ""
                print "        def onstdout(self, idx, line):"
                print "            return None"
                print ""
                print "        def onstderr(self, idx, line):"
                print "            return None"
                next
            }
            { print }
        ' "${mux_py}" > "${mux_py}.new"
        mv "${mux_py}.new" "${mux_py}"
    fi

    # typing_extensions on kirkstone is too old and misses dataclass_transform.
    # Replace with a no-op decorator fallback.
    if [ -f "${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/utils/dataclass.py" ]; then
        dataclass_py="${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/utils/dataclass.py"
        awk '
            BEGIN { skip = 0 }
            {
                if (skip) {
                    if ($0 ~ /^    from typing_extensions import dataclass_transform/) {
                        skip = 0
                    }
                    next
                }
                if ($0 ~ /^try:$/) {
                    print "try:"
                    print "    from typing import dataclass_transform  # type: ignore[attr-defined]"
                    print "except ImportError:  # pragma: no cover"
                    print "    def dataclass_transform(*args, **kwargs):"
                    print "        def _wrap(cls):"
                    print "            return cls"
                    print "        return _wrap"
                    skip = 1
                    next
                }
                print
            }
        ' "${dataclass_py}" > "${dataclass_py}.new"
        mv "${dataclass_py}.new" "${dataclass_py}"
    fi

    # Python 3.10 fallback if exceptiongroup backport is unavailable.
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/exceptiongroup
    cat >${D}${PYTHON_SITEPACKAGES_DIR}/exceptiongroup/__init__.py <<'EOF'
class BaseExceptionGroup(Exception):
    def __init__(self, message, exceptions):
        super().__init__(message)
        self.exceptions = tuple(exceptions)


class ExceptionGroup(BaseExceptionGroup):
    pass
EOF

    # Restore CLI module and launcher needed by webtv stream scripts.
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink_cli
    if [ -d "${S}/src/streamlink_cli" ]; then
        cp -a --no-preserve=ownership ${S}/src/streamlink_cli/. ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink_cli/
    fi

    install -d ${D}${bindir}
    cat >${D}${bindir}/streamlink <<'EOF2'
#!/usr/bin/env python3
from streamlink_cli.main import main

if __name__ == "__main__":
    raise SystemExit(main())
EOF2
    chmod 0755 ${D}${bindir}/streamlink
}

FILES:${PN}:append = " \
    ${bindir}/streamlink \
    ${PYTHON_SITEPACKAGES_DIR}/exceptiongroup \
    ${PYTHON_SITEPACKAGES_DIR}/streamlink \
    ${PYTHON_SITEPACKAGES_DIR}/streamlink_cli \
"
