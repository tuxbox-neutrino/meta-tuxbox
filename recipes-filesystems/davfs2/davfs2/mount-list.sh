# Shared implementation for the two davfs2 lifecycle commands.
# SPDX-License-Identifier: MIT

# Keep all diagnostics independent of URLs and command output: either may
# contain credentials. The line number identifies the entry to repair.
davfs_run() {
    local action=$1 list=$2 line url point extra authority current source type
    local number=0 completed=0 skipped=0 failed=0 status
    if [[ ! -r $list || ! -f $list ]]; then
        echo "davfs2: mount list is not a readable regular file." >&2
        return 1
    fi
    # Distinguish an unavailable mount table/tool from an unmounted entry.
    if ! findmnt --kernel --raw --noheadings --output TARGET >/dev/null 2>&1; then
        echo "davfs2: cannot inspect the mount table." >&2
        return 1
    fi
    while IFS= read -r line || [[ -n $line ]]; do
        ((number += 1))
        [[ $line =~ ^[[:space:]]*($|#) ]] && continue
        url= point= extra=
        read -r url point extra <<< "$line"
        if [[ $extra == ignore_cert ]]; then
            echo "davfs2: line $number: ignore_cert is unsupported; configure trust_ca_cert or trust_server_cert in davfs2.conf." >&2
            ((failed += 1))
            continue
        fi
        authority=${url#*://}
        authority=${authority%%/*}
        if [[ ! $url =~ ^https?://[^/[:space:]]+ || -z $authority || $authority == *@* ||
              $url == *\\* || $point != /* || $point == / || $point == *\\* ||
              -n $extra || $url =~ [[:space:]] || $point =~ [[:space:]] || $point == *//* || $point == */./* || $point == */../* ||
              $point == */. || $point == */.. ]]; then
            echo "davfs2: line $number: expected HTTP(S) URL without userinfo and an absolute mountpoint (two fields, no whitespace within fields)." >&2
            ((failed += 1))
            continue
        fi
        current=$(findmnt --kernel --raw --noheadings --mountpoint "$point" --output SOURCE,FSTYPE 2>/dev/null)
        status=$?
        if ((status > 1)); then
            echo "davfs2: line $number: mount inspection failed." >&2
            ((failed += 1))
            continue
        fi
        if [[ -n $current ]]; then
            source= type=
            read -r source type <<< "$current"
            # davfs2 1.7.3 uses mount(..., "fuse", ...), without a subtype.
            if [[ $current == *$'\n'* || $source != "$url" || ( $type != fuse && $type != fuse.davfs ) ]]; then
                echo "davfs2: line $number: mountpoint is occupied by a different mount; left untouched." >&2
                ((failed += 1))
                continue
            fi
            if [[ $action == mount ]]; then
                ((skipped += 1))
                continue
            fi
            if umount -- "$point" </dev/null >/dev/null 2>&1; then
                ((completed += 1))
            else
                echo "davfs2: line $number: unmount failed." >&2
                ((failed += 1))
            fi
        elif [[ $action == umount ]]; then
            ((skipped += 1))
        elif mkdir -p -- "$point" >/dev/null 2>&1 &&
             mount.davfs "$url" "$point" </dev/null >/dev/null 2>&1; then
            ((completed += 1))
        else
            echo "davfs2: line $number: mount failed; check network, secrets and trusted certificates." >&2
            ((failed += 1))
        fi
    done < "$list"
    echo "davfs2 $action: $completed completed, $skipped skipped, $failed failed."
    ((failed == 0))
}
