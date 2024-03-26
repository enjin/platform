<?php

return [
    /*
    |--------------------------------------------------------------------------
    | The scan threshold
    |--------------------------------------------------------------------------
    |
    | Sets a threshold on how many times a user can try scanning a QR code.
    | If null/0, means no limit.
    |
    */
    'scan_limit' => null,

    /*
    |--------------------------------------------------------------------------
    | The batch processing configuration
    |--------------------------------------------------------------------------
    |
    | The claims are processed in batches to save transaction fees.
    | polling - The timing interval in seconds for processing new claim batches
    | threshold - If reached, the claims will be processed
    | time_duration (minutes) - If not null/0, the claims will be processed
    |            after this duration, even when the threshold has not been met
    |
    */
    'batch_process' => [
        'polling' => env('BEAM_BATCH_POLLING', 6),
        'threshold' => env('BEAM_BATCH_THRESHOLD', 150),
        'time_duration' => env('BEAM_BATCH_MAX_WAITING_TIME', null),
    ],

    /*
    |--------------------------------------------------------------------------
    | The unit price
    |--------------------------------------------------------------------------
    |
    | The amount to set when minting.
    |
    */
    'unit_price' => env('BEAM_TOKEN_UNIT_PRICE', 10000000000000000),

    /*
    |--------------------------------------------------------------------------
    | The claim redirect url
    |--------------------------------------------------------------------------
    |
    | Here you may set the redirect URL when claiming.
    |
    */
    'claim_redirect' => env('CLAIM_REDIRECT', null),

    /*
    |--------------------------------------------------------------------------
    | Prune expired claims
    |--------------------------------------------------------------------------
    |
    | Here you may set the number of days to prune expired claims.
    | When set to null, expired claims will not be pruned.
    |
    */
    'prune_expired_claims' => env('PRUNE_EXPIRED_CLAIMS', 30),
];
