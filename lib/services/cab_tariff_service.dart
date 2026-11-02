import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cab_tariff_item.dart';
import 'api_service.dart';

class CabTariffService {
  static const String cacheKey = 'tc_custom_cab_tariffs';

  static List<CabTariffItem> getDefaultFleet() {
    return [
      CabTariffItem(
        id: 'sedan',
        name: 'AC Sedan (Swift Dzire / Etios)',
        capacity: '4 Passengers + Driver',
        packageSurcharge: 0,
        ratePerKm: 12.0,
        local8h80k: 1800,
        airportTransfer: 1100,
        driverDa: 400,
        isActive: true,
      ),
      CabTariffItem(
        id: 'ertiga',
        name: 'Maruti Ertiga / XL6 (Budget MUV)',
        capacity: '6 Passengers + Driver',
        packageSurcharge: 1500,
        ratePerKm: 15.0,
        local8h80k: 2400,
        airportTransfer: 1500,
        driverDa: 400,
        isActive: true,
      ),
      CabTariffItem(
        id: 'innova',
        name: 'Toyota Innova Crysta (Luxury SUV)',
        capacity: '6-7 Passengers + Driver',
        packageSurcharge: 3500,
        ratePerKm: 19.0,
        local8h80k: 3000,
        airportTransfer: 2000,
        driverDa: 450,
        isActive: true,
      ),
      CabTariffItem(
        id: 'tempo_12',
        name: 'Force Tempo Traveller (12 Seater)',
        capacity: '12 Passengers + Chauffeur',
        packageSurcharge: 8000,
        ratePerKm: 25.0,
        local8h80k: 4500,
        airportTransfer: 3000,
        driverDa: 500,
        isActive: true,
      ),
      CabTariffItem(
        id: 'tempo_17',
        name: 'Force Tempo Traveller (17/20 Seater)',
        capacity: '17-20 Passengers + Chauffeur',
        packageSurcharge: 12000,
        ratePerKm: 28.0,
        local8h80k: 5500,
        airportTransfer: 3800,
        driverDa: 600,
        isActive: true,
      ),
      CabTariffItem(
        id: 'urbania_12',
        name: 'Force Urbania Luxury (10/12 Seater)',
        capacity: '10-12 Passengers + Chauffeur',
        packageSurcharge: 14000,
        ratePerKm: 32.0,
        local8h80k: 6500,
        airportTransfer: 4500,
        driverDa: 600,
        isActive: true,
      ),
      CabTariffItem(
        id: 'coach_26',
        name: 'Force / Tata Luxury Mini-Bus (26 Seater)',
        capacity: '26 Passengers + Chauffeur',
        packageSurcharge: 18000,
        ratePerKm: 35.0,
        local8h80k: 7500,
        airportTransfer: 5000,
        driverDa: 700,
        isActive: true,
      ),
    ];
  }

  /// Load fleet tariffs from cache first, then sync with WordPress API
  static Future<List<CabTariffItem>> loadFleet({ApiService? apiService}) async {
    List<CabTariffItem> list = [];

    // 1. SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(cacheKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr);
        if (decoded is List && decoded.isNotEmpty) {
          list = decoded
              .map((e) => CabTariffItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error reading cached fleet: $e');
    }

    if (list.isEmpty) {
      list = getDefaultFleet();
    }

    // 2. Fetch from cloud REST API if available
    if (apiService != null) {
      try {
        final remote = await apiService.fetchCabTariffs();
        if (remote != null && remote.isNotEmpty) {
          list = remote.map((e) => CabTariffItem.fromJson(e)).toList();
          // Update cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(list.map((c) => c.toJson()).toList()));
        }
      } catch (e) {
        debugPrint('Error syncing fleet from server: $e');
      }
    }

    return list;
  }

  /// Save fleet tariffs to local storage and sync with server
  static Future<bool> saveFleet(List<CabTariffItem> fleet, {ApiService? apiService}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(fleet.map((c) => c.toJson()).toList()));

      if (apiService != null) {
        return await apiService.saveCabTariffs(fleet.map((c) => c.toJson()).toList());
      }
      return true;
    } catch (e) {
      debugPrint('Error saving fleet tariffs: $e');
      return false;
    }
  }
}
