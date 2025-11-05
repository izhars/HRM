import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class EmployeeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoading = false;
  String? _error;

  List<Employee> get employees => _employees;
  Employee? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/employees');
      if (response['success']) {
        _employees = (response['data'] as List)
            .map((json) => Employee.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Employee?> getEmployeeById(String id) async {
    try {
      final response = await _apiService.get('/employees/$id');
      if (response['success']) {
        return Employee.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<bool> createEmployee(Employee employee) async {
    try {
      final response = await _apiService.post('/employees', employee.toJson());
      if (response['success']) {
        await fetchEmployees();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateEmployee(Employee employee) async {
    try {
      final response = await _apiService.put('/employees/${employee.id}', employee.toJson());
      if (response['success']) {
        await fetchEmployees();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      final response = await _apiService.delete('/employees/$id');
      if (response['success']) {
        await fetchEmployees();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void selectEmployee(Employee employee) {
    _selectedEmployee = employee;
    notifyListeners();
  }
}