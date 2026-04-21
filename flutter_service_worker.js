'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/assets/pictures/challenge_read-20.jpg": "a8c01882a2b140fb2cb32113cb156524",
"assets/assets/pictures/challenge_skip-dinner.jpg": "e274e5bf4d50a8e99b6bbd210902ac3f",
"assets/assets/pictures/challenge_zero-scroll.jpg": "bc7872a022a34a29a5745ee56b5bf167",
"assets/assets/pictures/challenge_10pm-bedtime.jpg": "3a11f48829d4eb4a0aec98761d7c531c",
"assets/assets/pictures/challenge_workout-30.jpg": "6bc14d42841130621968f85913ebc096",
"assets/assets/pictures/challenge_create-20.jpg": "e7d16b918b0f35b3e2060900aed263a1",
"assets/assets/pictures/challenge_walk-30.jpg": "78158d81ba1a3650a19d9bd88ad4a62f",
"assets/assets/pictures/challenge_stretch-10.jpg": "1786b4546a73a0ab01823086030b065f",
"assets/assets/pictures/challenge_full-keto.jpg": "7aecaa30fbffba7868bb7ffddad0f920",
"assets/assets/pictures/challenge_learn-20.jpg": "0975629e498ded9e6b4deb35cb84daa3",
"assets/assets/pictures/challenge_shake-10.jpg": "d5296934d3baaed7151bccb80a414248",
"assets/assets/pictures/challenge_5am-club.jpg": "3afd4658eb5c7c020960cc9304ada0e5",
"assets/assets/pictures/challenge_cold-showers.jpg": "ae418f232ba3fd2eb40906ebb4646ade",
"assets/assets/pictures/challenge_6am-breakfast.jpg": "33092e721d874107aa58f2effb5a6558",
"assets/assets/pictures/challenge_6pm-dinner.jpg": "abd77774aa3bf808e069361532952135",
"assets/assets/pictures/challenge_hydrate-2.jpg": "a9a825cd70014b412339a94cf454a1b1",
"assets/assets/pictures/challenge_rebound-10.jpg": "27212ff32860710326f488cd38a99516",
"assets/assets/pictures/challenge_zero-gluten.jpg": "799c924212d9ea4f959434c862c37520",
"assets/assets/pictures/challenge_default_1080.jpg": "12c6b4ab4a520dc35289bb9e1955d8c5",
"assets/assets/pictures/challenge_zero-alcohol.jpg": "070681e7296fe8ac9a90fe0d7f75f8b4",
"assets/assets/misc/misc_logo512.svg": "20518938856fd76f33f21187bbe2fc6e",
"assets/assets/misc/misc_appLogo.svg": "8516e54d81f2943a1f66755da0b843ba",
"assets/assets/misc/littlewin_logo_text.svg": "7b6067427fcf88ce3bc889901c7e5b1a",
"assets/assets/misc/misc_appLogo108.png": "d5769275a65b57811539a86efc53a8e7",
"assets/assets/misc/misc_appLogo.png": "93431ca0004ea5b356938240a5a0d4f3",
"assets/assets/misc/misc_appLogo108.svg": "ec9874e7bfa1218c9eccfc551f38a1e6",
"assets/assets/misc/misc_appLogo1024.png": "e3494539160b88a19e2b0da214f4522f",
"assets/assets/misc/confetti.png": "719f77deceee3c0d2883f19d321be1e0",
"assets/assets/misc/streak_ring_218x128.png": "c0a62b7c27baea3cf0421c152ebab4d1",
"assets/assets/misc/misc_appLogoTransparent.png": "aff591d213d4cc5880fc81310df53a67",
"assets/assets/misc/misc_appLogo1024.svg": "f28104a96457ebbd452215fcf7347ba9",
"assets/assets/avatars/avatar_blank.jpg": "7993d19a84ac0d75df97ba303ee24639",
"assets/assets/fonts/Rubik-VariableFont_wght.ttf": "afc324d8b8ab76eb8dd2f42bcb1aff4e",
"assets/assets/fonts/Rubik-Italic-VariableFont_wght.ttf": "638f8444cc627365565c0991b43bdc24",
"assets/assets/icons/adjust_right_one.svg": "d5e5f2ae0cd1513c4555094a7249ea45",
"assets/assets/icons/adjust_left_double.svg": "a754fed81578aa2451b78b715149a11e",
"assets/assets/icons/misc_plus.svg": "348bc07cab7b57b59f8c623ec9ca0b59",
"assets/assets/icons/nav_checkin.svg": "f4bc990dbe33ec55b998afbb4dd78361",
"assets/assets/icons/misc_bell.svg": "0c5eef2814765394f2236bb8c6accc46",
"assets/assets/icons/stake-gift_box.png": "926e12c785631516be087560ee50830b",
"assets/assets/icons/tag_stake_plan.svg": "52f2c0123dad36088dfe0b60771b3be5",
"assets/assets/icons/misc_restart.svg": "98b480ead8b8212bd7933f71148507d0",
"assets/assets/icons/nav_scores.svg": "f9aed301f53847bbbe7756d588687b00",
"assets/assets/icons/misc_join.svg": "af1230b53011b7e126fdbbd632d979d5",
"assets/assets/icons/misc_add_contact.svg": "55989b2c4d9ecb19f0411f6ca1910158",
"assets/assets/icons/misc_info_fill.svg": "a9673d58bfdd185164574b2600d0af44",
"assets/assets/icons/misc_checkmark.svg": "d95e3e512f49f5601e4c9b3f4d94e19b",
"assets/assets/icons/misc_streak.svg": "9a8f15b2d81c946b0faad7d1c0b68533",
"assets/assets/icons/arrows_down.svg": "563be3bb05c14ca65e95f9df3f36508a",
"assets/assets/icons/arrows_up.svg": "e4f4e149fd92f220e6a90bfb2f69ea02",
"assets/assets/icons/stake-restaurant_dinner.png": "ef9d0e70d939b56a7a618c820e190a63",
"assets/assets/icons/stake-wine_bottle.png": "15978d4fb9ca6a763a7ec8a33577a134",
"assets/assets/icons/misc_list_dropdown.svg": "acc9ae524dc4f5d1f4986ca16447975c",
"assets/assets/icons/stake-massage_session.png": "ccd547ba4bac49bfb383e3af434b9f2c",
"assets/assets/icons/stake-spa_access.png": "69b4ada450c50000ecb65aefc2cad379",
"assets/assets/icons/stake-brunch_invite.png": "65db60be82360adf8c7a89ea204d05f4",
"assets/assets/icons/misc_menu_lines.svg": "347e8243dcfbf8c28f01fc843e113055",
"assets/assets/icons/arrows_back.svg": "4690b1e7cb5e1cfe2dacdb38bcfec332",
"assets/assets/icons/misc_crown.svg": "65adb9a389ed30dee8fcdb6dff9fb331",
"assets/assets/icons/misc_bet.svg": "0cea37117551a513f40acaf1c0ad8402",
"assets/assets/icons/misc_cog.svg": "9aeb29657f58b4b6ac0da045eaca4cc7",
"assets/assets/icons/misc_filter.svg": "9e39b2961cd4cbefbb98e3a802785357",
"assets/assets/icons/misc_incognito.svg": "d03192f3ac5b5aecb48651e8062a4ae0",
"assets/assets/icons/stake-chocolate_box.png": "3f28a1c71d23de27d3057b85788e8817",
"assets/assets/icons/misc_info.svg": "8a88de7e8753ee457644a3a5449dfa06",
"assets/assets/icons/misc_cross.svg": "44ca451e768c31d0fddfca723c9536f8",
"assets/assets/icons/nav_home.svg": "9a2ac41f4d809a0d66030f9ccd5b6c33",
"assets/assets/icons/adjust_left_one.svg": "2f768d804f0fd27cd6fd4a73cf992bb5",
"assets/assets/icons/misc_heart_outline.svg": "a464da440b4389bbdbc4b9cd6e55650a",
"assets/assets/icons/misc_send.svg": "6d19483c30aba0c62bb2ec5e9103fd4a",
"assets/assets/icons/adjust_right_double.svg": "ec2680242a8f8988cecaa4978f8bb217",
"assets/assets/icons/nav_people.svg": "0a3151fd003d033c752902a76c9b8314",
"assets/assets/icons/stake-cinema_night.png": "9de1cf2207273cff8fe2efee84ff43ad",
"assets/assets/icons/misc_menu_dots.svg": "7ef2456efd9e065d9831556fb21f1f11",
"assets/assets/icons/tag_stake_gift.svg": "d722ed161fe4f6d1c5741cabfd8bdfd6",
"assets/assets/icons/stake-drinks_round.png": "d718dae95d58e9bf41c8947dae0f148e",
"assets/assets/icons/stake-coffee_cup.png": "7308b20694797760ed5d614adec812c9",
"assets/assets/icons/arrows_next.svg": "642ec4b10ef7e03fdf4208eecab978c0",
"assets/assets/icons/misc_heart_fill.svg": "82ceddca2b10837b00ccc0165967b70e",
"assets/assets/data/username_components.json": "d665d0c8b756fcc63b0de46dd2e4bffa",
"assets/AssetManifest.json": "48770b3df192b493ce137da9d58d87ed",
"assets/AssetManifest.bin.json": "6da8b13bf6fd81530142d04753e188a6",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "531977c71df8b25f2b03ddb556441bdb",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "59b1edef6b3e182bfb10a6ce9c4dd124",
"assets/AssetManifest.bin": "ddbef72565bc0cd16c0a50da5117900d",
"assets/NOTICES": "efe6aad51afbb589f355b20397875c7b",
"assets/FontManifest.json": "a872b0fc5621a59b9d605755dba48164",
"favicon.png": "e3494539160b88a19e2b0da214f4522f",
"manifest.json": "51e48862db042644a3e9c62bf203b080",
"index.html": "e44a132435006e68a13ceef1bfc2ed80",
"/": "e44a132435006e68a13ceef1bfc2ed80",
"splash/img/dark-2x.png": "d5eeed40631131b8fd902862ed0fcf31",
"splash/img/dark-1x.png": "be8ed7b31cf4c4a60f906748e0a49874",
"splash/img/dark-3x.png": "ff968e0b0c63bf8481b95b06c1df9e14",
"splash/img/light-4x.png": "a26eb85cf23d93bffa60e125be38e2ae",
"splash/img/light-1x.png": "be8ed7b31cf4c4a60f906748e0a49874",
"splash/img/light-2x.png": "d5eeed40631131b8fd902862ed0fcf31",
"splash/img/dark-4x.png": "a26eb85cf23d93bffa60e125be38e2ae",
"splash/img/light-3x.png": "ff968e0b0c63bf8481b95b06c1df9e14",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "7b7770b7d933771b55d572cc3e425691",
"main.dart.js": "307dc09de91034c9cb14bc087ad49835",
"version.json": "b087d122305e982123cb0e04b07327f0",
"icons/Icon-maskable-512.png": "d5eeed40631131b8fd902862ed0fcf31",
"icons/app_logo.png": "93431ca0004ea5b356938240a5a0d4f3",
"icons/app_logo.svg": "8516e54d81f2943a1f66755da0b843ba",
"icons/Icon-maskable-192.png": "4f16510a4d6803df50671e181756c97b",
"icons/Icon-512.png": "d5eeed40631131b8fd902862ed0fcf31",
"icons/Icon-192.png": "4f16510a4d6803df50671e181756c97b",
"icons/apple-touch-icon.png": "e3494539160b88a19e2b0da214f4522f"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
