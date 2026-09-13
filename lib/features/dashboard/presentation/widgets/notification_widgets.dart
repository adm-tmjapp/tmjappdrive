import 'package:flutter/material.dart';

// ==========================================
// 1. CONSTANTES E TEMA
// ==========================================
class AppColors {
  static const Color background = Color(0xFF08080A);
  static const Color card = Color(0xFF141416);
  static const Color border = Color(0xFF222225);
  static const Color primaryAccent = Color(0xFFD62B78); // Rosa do App
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color iconBackground = Color(0xFF2A2A2D);
}

// ==========================================
// 2. MODELO DE DADOS
// ==========================================
class NotificationModel {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;

  NotificationModel({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    this.iconColor = AppColors.textPrimary,
    this.isUnread = false,
  });
}

// ==========================================
// 3. TELA PRINCIPAL
// ==========================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0;

  // Mock de dados simulando uma API
  final List<NotificationModel> _todayNotifications = [
    NotificationModel(
      title: 'Bônus Atingido!',
      description:
          'Você completou 12 corridas hoje e ganhou um bônus de R\$ 50,00. Confira sua carteira.',
      time: 'Agora',
      icon: Icons.attach_money_rounded,
      iconColor: AppColors.primaryAccent,
      isUnread: true,
    ),
    NotificationModel(
      title: 'Aviso de Trânsito',
      description:
          'Avenida Paulista com bloqueio parcial devido a obras na via. Rotas foram atualizadas.',
      time: '14:30',
      icon: Icons.info_outline_rounded,
    ),
  ];

  final List<NotificationModel> _olderNotifications = [
    NotificationModel(
      title: 'Corrida Cancelada',
      description:
          'O passageiro cancelou a solicitação para o Jardim Europa. A taxa de cancelamento foi aplicada.',
      time: 'Ontem',
      icon: Icons.cancel_outlined,
      iconColor: Colors.redAccent,
    ),
    NotificationModel(
      title: 'Nova Atualização',
      description:
          'Uma nova versão do aplicativo está disponível com melhorias no mapa e GPS.',
      time: 'Ontem',
      icon: Icons.system_update_alt_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificações',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Lógica para marcar todas como lidas
            },
            child: const Text(
              'Lidas',
              style: TextStyle(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSectionTitle('Hoje'),
                ..._todayNotifications
                    .map((notif) => NotificationCard(notification: notif))
                    .toList(),
                const SizedBox(height: 16),
                _buildSectionTitle('Anteriores'),
                ..._olderNotifications
                    .map((notif) => NotificationCard(notification: notif))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // COMPONENTE: BARRA DE FILTROS
  // ==========================================
  Widget _buildFilters() {
    final filters = ['TODAS', 'ALERTAS', 'PROMO'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                margin: EdgeInsets.only(
                  right: index != filters.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryAccent : AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      isSelected ? null : Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ==========================================
// COMPONENTE: CARD DE NOTIFICAÇÃO
// ==========================================
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de "Não lido" (Bolinha rosa)
          SizedBox(
            width: 12,
            child:
                notification.isUnread
                    ? Container(
                      margin: const EdgeInsets.only(top: 18),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                    : const SizedBox(),
          ),
          // Ícone circular
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.icon,
              color: notification.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      notification.time,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4, // Melhora a legibilidade (line-height)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
