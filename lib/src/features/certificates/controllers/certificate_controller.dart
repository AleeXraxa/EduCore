import 'dart:async';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/features/certificates/models/certificate.dart';
import 'package:flutter/foundation.dart';

class CertificateController extends ChangeNotifier {
  final _service = AppServices.instance.certificateService;
  
  List<Certificate> _allCertificates = [];
  List<Certificate> _filteredCertificates = [];
  bool _busy = false;
  String _searchQuery = '';
  CertificateType? _typeFilter;

  List<Certificate> get certificates => _filteredCertificates;
  bool get busy => _busy;

  // Stats
  int get totalCertificates => _allCertificates.length;
  int get generatedThisMonth {
    final now = DateTime.now();
    return _allCertificates.where((c) => 
      c.createdAt.month == now.month && c.createdAt.year == now.year
    ).length;
  }
  int get totalDownloads => _allCertificates.fold(0, (sum, c) => sum + c.downloadCount);
  int get activeTemplates => 7; // Currently fixed types

  StreamSubscription? _subscription;

  void init(String academyId) {
    if (_service == null) return;
    
    _busy = true;
    notifyListeners();

    _subscription = _service.watchCertificates(academyId).listen((certs) {
      _allCertificates = certs;
      _applyFilters();
      _busy = false;
      notifyListeners();
    });
  }

  void setSearch(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setTypeFilter(CertificateType? type) {
    _typeFilter = type;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredCertificates = _allCertificates.where((c) {
      final matchesSearch = c.studentName.toLowerCase().contains(_searchQuery) ||
          c.title.toLowerCase().contains(_searchQuery) ||
          c.id.toLowerCase().contains(_searchQuery);
      
      final matchesType = _typeFilter == null || c.type == _typeFilter;
      
      return matchesSearch && matchesType;
    }).toList();
    notifyListeners();
  }

  Future<void> deleteCertificate(String academyId, Certificate cert) async {
    if (_service == null) return;
    await _service.deleteCertificate(
      academyId: academyId,
      certificateId: cert.id,
      studentName: cert.studentName,
    );
  }

  Future<void> logDownload(String academyId, Certificate cert) async {
    if (_service == null) return;
    await _service.logDownload(
      academyId: academyId,
      certificateId: cert.id,
      studentName: cert.studentName,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
