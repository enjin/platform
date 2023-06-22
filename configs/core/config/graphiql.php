<?php declare(strict_types=1);

return [
    /*
    |--------------------------------------------------------------------------
    | Routes configuration
    |--------------------------------------------------------------------------
    |
    | Set the key as URI at which the GraphiQL UI can be viewed,
    | and add any additional configuration for the route.
    |
    | You can add multiple routes pointing to different GraphQL endpoints.
    |
    */

    'routes' => [
        '/graphiql' => [
            'name' => 'graphiql',
            'endpoint' => '/graphql',
            'subscription-endpoint' => null,
        ],
        '/graphiql/beam' => [
            'name' => 'graphiql.beam',
            'endpoint' => '/graphql/beam',
            'subscription-endpoint' => null,
        ],
        '/graphiql/fuel-tanks' => [
            'name' => 'graphiql.fuel-tanks',
            'endpoint' => '/graphql/fuel-tanks',
            'subscription-endpoint' => null,
        ],
        '/graphiql/marketplace' => [
            'name' => 'graphiql.marketplace',
            'endpoint' => '/graphql/marketplace',
            'subscription-endpoint' => null,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Control GraphiQL availability
    |--------------------------------------------------------------------------
    |
    | Control if the GraphiQL UI is accessible at all.
    | This allows you to disable it in certain environments,
    | for example you might not want it active in production.
    |
    */

    'enabled' => env('GRAPHIQL_ENABLED', true),
];
