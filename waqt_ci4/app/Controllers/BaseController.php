<?php

namespace App\Controllers;

use CodeIgniter\Controller;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use Psr\Log\LoggerInterface;

/**
 * BaseController provides a convenient place for loading components
 * and performing functions that are needed by all your controllers.
 *
 * Extend this class in any new controllers:
 * ```
 *     class Home extends BaseController
 * ```
 *
 * For security, be sure to declare any new methods as protected or private.
 */
abstract class BaseController extends Controller
{
    /**
     * Be sure to declare properties for any property fetch you initialized.
     * The creation of dynamic property is deprecated in PHP 8.2.
     */

    // protected $session;

    /**
     * @return void
     */
    public function initController(RequestInterface $request, ResponseInterface $response, LoggerInterface $logger)
    {
        // Load here all helpers you want to be available in your controllers that extend BaseController.
        // Caution: Do not put the this below the parent::initController() call below.
        // $this->helpers = ['form', 'url'];

        // Caution: Do not edit this line.
        parent::initController($request, $response, $logger);

        // Preload any models, libraries, etc, here.
        // $this->session = service('session');
    }

    protected function getMosqueRecommendations($limit = 2)
    {
        $mosquePool = [
            [
                'name' => 'Masjid Raya Al-Azhar',
                'distance' => '9.2 km',
                'description' => 'Ramah Jamaah & AC Berfungsi'
            ],
            [
                'name' => 'Masjid Istiqlal Jakarta',
                'distance' => '12.4 km',
                'description' => 'Tempat Wudhu Bersih & Spacious'
            ],
            [
                'name' => 'Masjid Sunda Kelapa',
                'distance' => '10.1 km',
                'description' => 'Suasana Teduh & Banyak Kajian'
            ],
            [
                'name' => 'Masjid At-Tin',
                'distance' => '15.6 km',
                'description' => 'Arsitektur Megah & Parkir Luas'
            ],
            [
                'name' => 'Masjid Cut Meutia',
                'distance' => '11.2 km',
                'description' => 'Bangunan Bersejarah & Strategis'
            ],
            [
                'name' => 'Masjid Ramlie Musofa',
                'distance' => '18.3 km',
                'description' => 'Desain Mirip Taj Mahal & Bersih'
            ],
            [
                'name' => 'Masjid Dian Al-Mahri (Kubah Emas)',
                'distance' => '24.5 km',
                'description' => 'Kubah Emas Megah & Halaman Luas'
            ],
            [
                'name' => 'Masjid Al-Irsyad Bandung',
                'distance' => '140 km',
                'description' => 'Desain Unik Tanpa Kubah & Futuristik'
            ],
            [
                'name' => 'Masjid Al-Jabbar',
                'distance' => '145 km',
                'description' => 'Masjid Terapung Megah & Indah'
            ],
            [
                'name' => 'Masjid Agung Trans Studio',
                'distance' => '138 km',
                'description' => 'Bersih, Nyaman & Full Karpet Lembut'
            ]
        ];

        $keys = array_rand($mosquePool, min($limit, count($mosquePool)));
        if (!is_array($keys)) {
            $keys = [$keys];
        }

        $result = [];
        foreach ($keys as $key) {
            $result[] = $mosquePool[$key];
        }
        return $result;
    }

    protected function getDailyReflection()
    {
        $reflectionPool = [
            [
                'quote' => '"Perumpamaan orang yang membaca Al-Qur\'an dan mengamalkannya bagaikan buah utrujah, rasanya lezat dan baunya harum."',
                'source' => '— HR. Bukhari & Muslim'
            ],
            [
                'quote' => '"Sesungguhnya shalat itu mencegah dari perbuatan keji dan mungkar. Dan ketahuilah mengingat Allah itu lebih besar keutamaannya."',
                'source' => '— QS. Al-Ankabut: 45'
            ],
            [
                'quote' => '"Barangsiapa yang menempuh jalan untuk mencari ilmu, maka Allah akan mudahkan baginya jalan menuju surga."',
                'source' => '— HR. Muslim'
            ],
            [
                'quote' => '"Senyummu di hadapan saudaramu adalah sedekah bagimu."',
                'source' => '— HR. Tirmidzi'
            ],
            [
                'quote' => '"Kebersihan itu sebagian dari iman."',
                'source' => '— HR. Muslim'
            ],
            [
                'quote' => '"Sebaik-baik manusia adalah yang paling bermanfaat bagi manusia lainnya."',
                'source' => '— HR. Ahmad'
            ],
            [
                'quote' => '"Sesungguhnya sesudah kesulitan itu ada kemudahan."',
                'source' => '— QS. Asy-Syarh: 6'
            ],
            [
                'quote' => '"Bertakwalah kepada Allah di mana saja kamu berada, dan ikutilah perbuatan buruk dengan perbuatan baik niscaya ia akan menghapusnya."',
                'source' => '— HR. Tirmidzi'
            ],
            [
                'quote' => '"Tidak sempurna iman salah seorang di antara kalian sampai ia mencintai untuk saudaranya apa yang ia cintai untuk dirinya sendiri."',
                'source' => '— HR. Bukhari & Muslim'
            ],
            [
                'quote' => '"Maka nikmat Tuhanmu yang manakah yang kamu dustakan?"',
                'source' => '— QS. Ar-Rahman: 13'
            ]
        ];

        return $reflectionPool[array_rand($reflectionPool)];
    }
}
