<?php

declare(strict_types=1);

return [
    'catalog_file' => '/var/lib/image-portal/catalog.json',
    'artifact_base_url' => '',
    'portal_base_url' => '',
    'legacy_download_path' => '/api/v1/download.php',
    'allowed_channels' => ['release', 'beta', 'nightly'],
    'default_channel' => 'nightly',
    'default_imagedir' => '',
    'json_cache_control' => 'public, max-age=60',
    'legacy_url_prefix' => '/legacy',
];
