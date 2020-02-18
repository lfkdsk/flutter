import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:tourism_demo/models/destination.dart';
import 'package:tourism_demo/utils/http_utils.dart';

class ServerAPI {
//  static String host = 'https://api.jsonbin.io/b/5b96db5eab9a186eafe86a97/1';
  static String host = 'https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/e115686ab8b643d9_1565682991538.json';
  // DESTINATIONS
  Future<List<Destination>> fetchDestinations() async {
    print('fetching destinations...');

    await Future.delayed(Duration(seconds: 1), () => false);
//    var url = '$host';

//    Response response = await getRequest(url, {
//      'Content-type': 'application/json; charset=utf-8',
//      'Accept': 'application/json'
//    });

    print("Future.delayed");
//    String body = utf8.decode(response.bodyBytes);
    String body = '''[
  {
    "activities": [
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/264e2a384221067e_1565677948458.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-16",
        "date_from": "2018-06-13",
        "city_ar": "إسطنبول",
        "city": "Istanbul"
      },
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/f11b32b284235637_1565677948459.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-20",
        "date_from": "2018-06-17",
        "city_ar": "طرابزون",
        "city": "Trabzon"
      },
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/44b971770840e01a_1565677948452.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-20",
        "date_from": "2018-06-17",
        "city_ar": "غريسون",
        "city": "Giresun"
      },
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/8c7fb985d38a03a6_1565677948581.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-20",
        "date_from": "2018-06-17",
        "city_ar": "أُردو",
        "city": "Ordu"
      }
    ],
    "date_to": "2018-06-20",
    "date_from": "2018-06-13",
    "short_description_ar": "8 أيام في فندق أربع نجوم/الخطوط الجوية التركية",
    "short_description": "8 days in a 4-star hotels/ Turkish Airlines",
    "hotel_stars": 4,
    "food_ar": "فطور",
    "food": "Breakfast",
    "airlines_ar": "الخطوط الجوية التركية",
    "airlines": "Turkish Airlines",
    "num_days": 7,
    "price": 900,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/1d4d3990a5f36ff5_1565677948301.jpg",
    "emoji": "🇹🇷",
    "title_ar": "تركيا",
    "title": "Turkey"
  },
  {
    "activities": [
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-18",
        "date_from": "2018-06-15",
        "city_ar": "ياسمين الحمامات",
        "city": "Yasmine Hammamet"
      },
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/c7d0c0f87c463476_1565677948388.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-23",
        "date_from": "2018-06-19",
        "city_ar": "تونس العاصمة",
        "city": "Capital of Tunisia"
      }
    ],
    "date_to": "2018-06-27",
    "date_from": "2018-06-15",
    "short_description_ar": "8 أيام في فندق خمس نجوم / الملكية الاردنية",
    "short_description": "8 days - five-star hotels / Royal Jordanian",
    "hotel_stars": 5,
    "food_ar": "فطور و عشاء",
    "food": "Breakfast and dinner",
    "airlines_ar": "الملكية الاردنية",
    "airlines": "Royal Jordanian",
    "num_days": 12,
    "price": 1100,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/cf4fd723cb6b3042_1565677948411.jpg",
    "emoji": "🇹🇳",
    "title_ar": "تونس",
    "title": "Tunisia"
  },
  {
    "activities": [
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/d4c251afe712faad_1565677948419.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-18",
        "date_from": "2018-06-14",
        "city_ar": "كوالالمبور",
        "city": "Kuala Lumpur"
      },
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/c7d0c0f87c463476_1565677948388.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-23",
        "date_from": "2018-06-19",
        "city_ar": "تونس العاصمة",
        "city": "Capital of Tunisia"
      }
    ],
    "date_to": "2018-06-29",
    "date_from": "2018-06-15",
    "short_description_ar": "10 أيام في فندق أربع و خمس نجوم /  الخطوط الجوية العراقية",
    "short_description": "10 days - five and four-star hotels / Iraqi Airlines",
    "hotel_stars": 5,
    "food_ar": "فطور",
    "food": "Breakfast",
    "airlines_ar": "الخطوط الجوية العراقية",
    "airlines": "Iraqi Airlines",
    "num_days": 14,
    "price": 1350,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/6386811edc72fc9b_1565677948488.jpg",
    "emoji": "🇮🇩",
    "title_ar": "إندونيسيا",
    "title": "Indonesia"
  },
  {
    "activities": [
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-15",
        "date_from": "2018-06-13",
        "city_ar": "كييڤ",
        "city": "Kiev"
      },
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-23",
        "date_from": "2018-06-19",
        "city_ar": "أوديسا",
        "city": "Odessa"
      }
    ],
    "date_to": "2018-06-18",
    "date_from": "2018-06-12",
    "short_description_ar": "8 أيام في فندق أربع نجوم /   الخطوط الجوية العراقية",
    "short_description": "5 days in a 4-star hotels/ Turkish Airlines",
    "hotel_stars": 4,
    "food_ar": "فطور و عشاء",
    "food": "Breakfast and dinner",
    "airlines_ar": "الخطوط الجوية العراقية (چارتر)",
    "airlines": "Iraqi Airlines (Charter)",
    "num_days": 5,
    "price": 1850,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/9feb177ed37b5bd4_1565677948538.jpg",
    "emoji": "🇺🇦",
    "title_ar": "أوكرانيا",
    "title": "Ukraine"
  },
  {
    "activities": [
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-15",
        "date_from": "2018-06-13",
        "city_ar": "كييڤ",
        "city": "Kiev"
      },
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-23",
        "date_from": "2018-06-19",
        "city_ar": "أوديسا",
        "city": "Odessa"
      }
    ],
    "date_to": "2018-06-26",
    "date_from": "2018-06-16",
    "short_description_ar": "8 أيام في فندق أربع نجوم /   الخطوط الجوية العراقية",
    "short_description": "5 days in a 4-star hotels/ Turkish Airlines",
    "hotel_stars": 4,
    "food_ar": "فطور و عشاء",
    "food": "Breakfast and dinner",
    "airlines_ar": "الخطوط الجوية العراقية (چارتر)",
    "airlines": "Iraqi Airlines (Charter)",
    "num_days": 10,
    "price": 700,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/c7f074431da713f8_1565677948444.jpg",
    "emoji": "🇦🇲",
    "title_ar": "ارمينيا",
    "title": "Armenia"
  },
  {
    "activities": [
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-18",
        "date_from": "2018-06-15",
        "city_ar": "القاهرة",
        "city": "Cairo"
      },
      {
        "photo": "https://media.tacdn.com/media/attractions-splice-spp-674x446/07/2c/0b/bd.jpg?fit=crop&w=960&h=416",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-23",
        "date_from": "2018-06-19",
        "city_ar": "شرم الشيخ",
        "city": "Sharm El Sheikh"
      }
    ],
    "date_to": "2018-06-21",
    "date_from": "2018-06-14",
    "short_description_ar": "7 أيام في فندق أربع نجوم /   الخطوط الجوية العراقية",
    "short_description": "7 days in a 4-star hotels/ Turkish Airlines",
    "hotel_stars": 7,
    "food_ar": "فطور و عشاءفطور و غداء و عشاء",
    "food": "Breakfast, launch, and dinner",
    "airlines_ar": "الخطوط الجوية العراقية",
    "airlines": "Iraqi Airlines",
    "num_days": 8,
    "price": 550,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/dc87413d170c1d38_1565677948340.jpg",
    "emoji": "🇪🇬",
    "title_ar": "مصر",
    "title": "Egypt"
  },
  {
    "activities": [
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/0abe87529f393e8e_1565677948351.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-15",
        "date_from": "2018-06-13",
        "city_ar": "إسطنبول",
        "city": "Istanbul"
      },
      {
        "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/2cad1ab6e5a84154_1565677948456.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-20",
        "date_from": "2018-06-16",
        "city_ar": "مرمريس",
        "city": "Marmaris"
      },
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-20",
        "date_from": "2018-06-16",
        "city_ar": "فتحية",
        "city": "Fethiye"
      },
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-20",
        "date_from": "2018-06-16",
        "city_ar": "بودروم",
        "city": "Bodrum"
      }
    ],
    "date_to": "2018-06-25",
    "date_from": "2018-06-15",
    "short_description_ar": "8 أيام في فندق أربع نجوم /   الخطوط الجوية العراقية",
    "short_description": "8 days in a 4-star hotels/ Turkish Airlines",
    "hotel_stars": 5,
    "food_ar": "فطور",
    "food": "Breakfast",
    "airlines_ar": "الخطوط الجوية العراقية (چارتر)",
    "airlines": "Iraqi Airlines (Charter)",
    "num_days": 10,
    "price": 780,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/2dcfeefd5ea1462c_1565677948298.jpg",
    "emoji": "🇹🇷",
    "title_ar": "تركيا",
    "title": "Turkey"
  },
  {
    "activities": [
      {
        "photo": "https://lonelyplanetimages.imgix.net/a/g/hi/t/585b69dfa6a5417f6e49fce3e5430ce5-beirut.jpg?sharp=10&vib=20&w=1200",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-18",
        "date_from": "2018-06-14",
        "city_ar": "بيروت",
        "city": "Beirut"
      },
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-18",
        "date_from": "2018-06-15",
        "city_ar": "فاريا",
        "city": "Faraya"
      },
      {
        "photo": "https://media.tacdn.com/media/attractions-splice-spp-674x446/06/d7/c8/42.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-23",
        "date_from": "2018-06-19",
        "city_ar": "البقاع",
        "city": "Beqaa"
      }
    ],
    "date_to": "2018-06-22",
    "date_from": "2018-06-14",
    "short_description_ar": "8 أيام في فندق أربع نجوم /   الخطوط الجوية العراقية",
    "short_description": "8 days in a 4-star hotels/ Turkish Airlines",
    "hotel_stars": 5,
    "food_ar": "فطور و غداء و عشاء",
    "food": "Breakfast, launch, and dinner",
    "airlines_ar": "الخطوط الجوية العراقية",
    "airlines": "Iraqi Airlines",
    "num_days": 8,
    "price": 550,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/bfb4135b951220d2_1565677948411.jpg",
    "emoji": "🇱🇧",
    "title_ar": "لبنان",
    "title": "Lebanon"
  },
  {
    "activities": [
      {
        "photo": "https://lonelyplanetimages.imgix.net/a/g/hi/t/585b69dfa6a5417f6e49fce3e5430ce5-beirut.jpg?sharp=10&vib=20&w=1200",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-18",
        "date_from": "2018-06-14",
        "city_ar": "بيروت",
        "city": "Beirut"
      },
      {
        "photo": null,
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-18",
        "date_from": "2018-06-15",
        "city_ar": "إسطنبول",
        "city": "Istanbul"
      },
      {
        "photo": "https://media.tacdn.com/media/attractions-splice-spp-674x446/06/d7/c8/42.jpg",
        "activity_ar": "",
        "activity": "",
        "date_to": "2018-06-23",
        "date_from": "2018-06-19",
        "city_ar": "أثينا",
        "city": "Athens"
      }
    ],
    "date_to": "2018-06-27",
    "date_from": "2018-06-13",
    "short_description_ar": "14 أيام في فندق أربع نجوم /   الخطوط الجوية العراقية",
    "short_description": "14 days in a 4-star hotels/ Turkish Airlines",
    "hotel_stars": 5,
    "food_ar": "فطور و غداء و عشاء",
    "food": "Breakfast, launch, and dinner",
    "airlines_ar": "خطوط الشرق الاوسط اللبنانية",
    "airlines": "Middle East Airlines",
    "num_days": 14,
    "price": 1750,
    "photo": "https://sf1-ttcdn-tos.pstatp.com/obj/developer-baas/baas/tt87806wd86mortv13/95509d289443e286_1565677948424.jpg",
    "emoji": "🛥 🇱🇧 🇹🇷 🇬🇷",
    "title_ar": "الرحلة البحرية",
    "title": "Sea Trip"
  }
]''';
    print("response.body=${body}");

    List responseJSON = json.decode(body);
    print("body decoded");
    List<Destination> destinations = responseJSON
        .map((destination) => Destination.fromJson(destination))
        .toList();

    print('${destinations.length} destinations fetched...');

    return destinations;
  }
}
