import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PermissionUtils {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return true;
    
    if (context.mounted) {
      _showErrorSnackbar(context, 'Se requiere permiso de cámara para tomar fotos.');
    }
    return false;
  }

  static Future<bool> requestGalleryPermission(BuildContext context) async {
    // Intentar fotos primero (Android 13+)
    var status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;

    // Intentar storage general (Android 12 o menor)
    status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) return true;
    
    // En Android 13+, image_picker utiliza el PhotoPicker nativo que no requiere
    // permisos de la aplicación. Por ende, si ambas peticiones de arriba fallan 
    // silenciosamente, permitimos que image_picker haga su trabajo.
    return true;
  }

  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.request();
    if (status.isGranted) return true;

    if (context.mounted) {
      _showErrorSnackbar(context, 'Se requiere permiso de ubicación para esta función.');
    }
    return false;
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Ajustes',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  static Future<String?> getCurrentCity(BuildContext context) async {
    final hasPermission = await requestLocationPermission(context);
    if (!hasPermission) return null;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          _showErrorSnackbar(context, 'El servicio de ubicación está desactivado.');
        }
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
          
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
      }
    } catch (e) {
      debugPrint('Error al obtener la ciudad: $e');
    }
    return null;
  }
}
