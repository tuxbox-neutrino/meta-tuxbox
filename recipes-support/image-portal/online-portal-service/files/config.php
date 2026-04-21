<?php

declare(strict_types=1);

return [
    'catalog_file' => '/var/lib/image-portal/catalog.json',
    // HTTP source: public base URL to static feed artifacts. Leave
    // empty to disable the HTTP source.
    'artifact_base_url' => '',
    // LocalDisk source: absolute filesystem path with the feed tree
    // (bind mount or local directory). Takes precedence over
    // artifact_base_url when set and existing on disk. Enables
    // direct byte streaming with HTTP Range support.
    'artifact_base_path' => '',
    'portal_base_url' => '',
    'legacy_download_path' => '/api/v1/download.php',
    'allowed_channels' => ['release', 'beta', 'nightly'],
    'default_channel' => 'nightly',
    'default_imagedir' => '',
    'json_cache_control' => 'public, max-age=60',
    'legacy_url_prefix' => '/legacy',
];
