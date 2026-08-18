import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum ChantierStatus { enCours, planifie, retard, termine, enAttente }

extension ChantierStatusExt on ChantierStatus {
  String get label {
    switch (this) {
      case ChantierStatus.enCours:
        return 'En cours';
      case ChantierStatus.planifie:
        return 'Planifié';
      case ChantierStatus.retard:
        return 'Retard';
      case ChantierStatus.termine:
        return 'Terminé';
      case ChantierStatus.enAttente:
        return 'En attente';
    }
  }

  Color get color {
    switch (this) {
      case ChantierStatus.enCours:
        return AppTheme.statusEnCours;
      case ChantierStatus.planifie:
        return AppTheme.statusPlanifie;
      case ChantierStatus.retard:
        return AppTheme.statusRetard;
      case ChantierStatus.termine:
        return AppTheme.statusTermine;
      case ChantierStatus.enAttente:
        return AppTheme.statusEnAttente;
    }
  }

  Color get bgColor {
    switch (this) {
      case ChantierStatus.enCours:
        return AppTheme.statusEnCours.withAlpha(31);
      case ChantierStatus.planifie:
        return AppTheme.statusPlanifie.withAlpha(31);
      case ChantierStatus.retard:
        return AppTheme.statusRetard.withAlpha(31);
      case ChantierStatus.termine:
        return AppTheme.statusTermine.withAlpha(31);
      case ChantierStatus.enAttente:
        return AppTheme.statusEnAttente.withAlpha(31);
    }
  }

  IconData get icon {
    switch (this) {
      case ChantierStatus.enCours:
        return Icons.play_circle_outline_rounded;
      case ChantierStatus.planifie:
        return Icons.schedule_rounded;
      case ChantierStatus.retard:
        return Icons.warning_amber_rounded;
      case ChantierStatus.termine:
        return Icons.check_circle_outline_rounded;
      case ChantierStatus.enAttente:
        return Icons.pause_circle_outline_rounded;
    }
  }

  static ChantierStatus fromString(String s) {
    switch (s) {
      case 'en_cours':
        return ChantierStatus.enCours;
      case 'planifie':
        return ChantierStatus.planifie;
      case 'retard':
        return ChantierStatus.retard;
      case 'termine':
        return ChantierStatus.termine;
      case 'en_attente':
        return ChantierStatus.enAttente;
      default:
        return ChantierStatus.planifie;
    }
  }
}

class StatusBadgeWidget extends StatelessWidget {
  final ChantierStatus status;
  final bool compact;

  const StatusBadgeWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 10 : 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: status.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
