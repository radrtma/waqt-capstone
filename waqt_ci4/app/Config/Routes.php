<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */
$routes->get('/', 'Home::index');
$routes->get('dashboard', 'Home::index');
$routes->get('prayer', 'Home::prayer');
$routes->get('history', 'Home::history');
$routes->get('profile', 'Home::profile');

$routes->get('login', 'Auth::login');
$routes->post('login', 'Auth::loginPost');
$routes->get('logout', 'Auth::logout');

$routes->get('community', 'Community::index');
$routes->get('community/post/create', 'Community::createPost');
$routes->post('community/post', 'Community::submitPost');
$routes->get('community/post/(:num)', 'Community::viewPost/$1');
$routes->get('community/post/edit/(:num)', 'Community::editPost/$1');
$routes->post('community/post/update/(:num)', 'Community::updatePost/$1');
$routes->get('community/post/delete/(:num)', 'Community::deletePost/$1');
$routes->post('community/comment/add', 'Community::addComment');
$routes->post('community/comment/delete', 'Community::deleteComment');
$routes->post('community/reply/add', 'Community::addReply');
$routes->post('community/reply/delete', 'Community::deleteReply');


$routes->group('api', function($routes) {
    // Auth Routes
    $routes->post('auth/register', 'Api\AuthController::register');
    $routes->post('auth/login', 'Api\AuthController::login');
    $routes->post('auth/update', 'Api\AuthController::updateProfile', ['filter' => 'apiauth']);

    // Sync Routes
    $routes->post('sync', 'Api\SyncController::sync', ['filter' => 'apiauth']);

    // Posts & Image Upload Routes
    $routes->get('posts', 'Api\PostController::index');
    $routes->get('posts/(:num)', 'Api\PostController::show/$1');
    $routes->post('posts', 'Api\PostController::create', ['filter' => 'apiauth']);
    $routes->put('posts/(:num)', 'Api\PostController::update/$1', ['filter' => 'apiauth']);
    $routes->delete('posts/(:num)', 'Api\PostController::delete/$1', ['filter' => 'apiauth']);
    
    // Post Reactions
    $routes->post('posts/(:num)/react', 'Api\PostController::react/$1');

    // Comments & Replies Routes
    $routes->get('posts/(:num)/comments', 'Api\PostController::getComments/$1');
    $routes->post('posts/(:num)/comments', 'Api\PostController::addComment/$1', ['filter' => 'apiauth']);
    $routes->delete('comments/(:num)', 'Api\PostController::deleteComment/$1', ['filter' => 'apiauth']);
    $routes->post('comments/(:num)/replies', 'Api\PostController::addReply/$1', ['filter' => 'apiauth']);
    $routes->delete('replies/(:num)', 'Api\PostController::deleteReply/$1', ['filter' => 'apiauth']);

    // Single Image Upload
    $routes->post('upload', 'Api\PostController::upload', ['filter' => 'apiauth']);
});
