import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;
  final Function(int) onPageChanged;
  final String? groupLabel; // Para personalizar el texto (ej: "Grupo" o "Página")

  const PaginationWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
    required this.onPageChanged,
    this.groupLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Validar que tenemos datos válidos
    if (totalPages <= 1 || totalItems <= 0 || itemsPerPage <= 0) {
      return const SizedBox.shrink();
    }

    // Asegurar que currentPage esté en el rango válido (1-based)
    final validCurrentPage = currentPage.clamp(1, totalPages);
    
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalPages,
        itemBuilder: (context, index) {
          // Validar que el índice esté en rango
          if (index < 0 || index >= totalPages) {
            return const SizedBox.shrink();
          }
          
          final pageNumber = index + 1; // Convertir a 1-based
          final isSelected = pageNumber == validCurrentPage;
          
          // Calcular el rango de elementos para esta página con validaciones adicionales
          final pageStart = (index * itemsPerPage + 1).clamp(1, totalItems);
          final pageEnd = ((index + 1) * itemsPerPage).clamp(pageStart, totalItems);
          
          // Validar que el rango sea válido
          if (pageStart > totalItems || pageEnd < pageStart) {
            return const SizedBox.shrink();
          }
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                // Validar que la página sea válida antes de llamar el callback
                if (pageNumber >= 1 && pageNumber <= totalPages) {
                  onPageChanged(pageNumber);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[700] : const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue[900]! : const Color.fromARGB(255, 255, 255, 255)!,
                  ),
                ),
                child: Text(
                  '$pageStart-$pageEnd',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PaginationInfo extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int currentPageItems;
  final int totalItems;

  const PaginationInfo({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.currentPageItems,
    required this.totalItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Página ${currentPage + 1} de $totalPages • $currentPageItems elementos de $totalItems',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}