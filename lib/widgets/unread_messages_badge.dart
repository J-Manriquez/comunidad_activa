import 'package:flutter/material.dart';
import '../services/unread_messages_service.dart';

class UnreadMessagesBadge extends StatelessWidget {
  final String condominioId;
  final String chatId;
  final String usuarioId;
  final UnreadMessagesService unreadService;
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const UnreadMessagesBadge({
    Key? key,
    required this.condominioId,
    required this.chatId,
    required this.usuarioId,
    required this.unreadService,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.fontSize,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: unreadService.getUnreadMessagesStream(
        condominioId: condominioId,
        chatId: chatId,
        usuarioId: usuarioId,
      ),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        if (unreadCount == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: padding ?? const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: fontSize ?? 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Widget para mostrar contador en ListTile
class UnreadMessagesListTile extends StatelessWidget {
  final String condominioId;
  final String chatId;
  final String usuarioId;
  final UnreadMessagesService unreadService;
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;

  const UnreadMessagesListTile({
    Key? key,
    required this.condominioId,
    required this.chatId,
    required this.usuarioId,
    required this.unreadService,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: unreadService.getUnreadMessagesStream(
        condominioId: condominioId,
        chatId: chatId,
        usuarioId: usuarioId,
      ),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return ListTile(
          leading: UnreadMessagesBadge(
            condominioId: condominioId,
            chatId: chatId,
            usuarioId: usuarioId,
            unreadService: unreadService,
            child: leading,
          ),
          title: title,
          subtitle: subtitle,
          // trailing: unreadCount > 0
          //     ? Container(
          //         padding: const EdgeInsets.symmetric(
          //           horizontal: 8,
          //           vertical: 4,
          //         ),
          //         decoration: BoxDecoration(
          //           color: Colors.red,
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         child: Text(
          //           unreadCount > 99 ? '99+' : unreadCount.toString(),
          //           style: const TextStyle(
          //             color: Colors.white,
          //             fontSize: 12,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       )
          //     : null,
          contentPadding: contentPadding,
          onTap: onTap,
        );
      },
    );
  }
}

// Widget para mostrar contador total en AppBar o BottomNavigationBar
class TotalUnreadMessagesBadge extends StatelessWidget {
  final String condominioId;
  final String usuarioId;
  final bool isAdmin;
  final UnreadMessagesService unreadService;
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;

  const TotalUnreadMessagesBadge({
    Key? key,
    required this.condominioId,
    required this.usuarioId,
    required this.isAdmin,
    required this.unreadService,
    required this.child,
    this.badgeColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: unreadService.getUserChats(
        condominioId: condominioId,
        usuarioId: usuarioId,
        isAdmin: isAdmin,
      ),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData || chatSnapshot.data!.isEmpty) {
          return child;
        }

        final chatIds = chatSnapshot.data!.map((chat) => chat['id']!).toList();

        return StreamBuilder<Map<String, int>>(
          stream: unreadService.getMultipleUnreadCountsStream(
            condominioId: condominioId,
            chatIds: chatIds,
            usuarioId: usuarioId,
          ),
          builder: (context, snapshot) {
            final unreadCounts = snapshot.data ?? {};
            final totalUnread = unreadCounts.values.fold(0, (sum, count) => sum + count);
            
            if (totalUnread == 0) {
              return child;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      totalUnread > 99 ? '99+' : totalUnread.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}