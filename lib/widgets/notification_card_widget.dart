import 'package:flutter/material.dart';

class NotificationCardWidget extends StatelessWidget {
  final int unreadCount;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const NotificationCardWidget({
    super.key,
    required this.unreadCount,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Colors.blue.shade600;
    final hasNotifications = unreadCount > 0;

    return Card(
      elevation: hasNotifications ? 6 : 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: hasNotifications
                ? LinearGradient(
                    colors: [cardColor, cardColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: hasNotifications ? null : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasNotifications 
                      ? Colors.white.withOpacity(0.2)
                      : cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications,
                  color: hasNotifications ? Colors.white : cardColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hasNotifications ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasNotifications
                          ? '$unreadCount notificación${unreadCount > 1 ? 'es' : ''} sin leer'
                          : 'No hay notificaciones nuevas',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasNotifications 
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasNotifications)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios,
                color: hasNotifications ? Colors.white : Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}