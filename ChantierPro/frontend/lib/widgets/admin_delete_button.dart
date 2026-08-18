import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/auth_session.dart';

/// Bouton poubelle qui ne s'affiche QUE si l'utilisateur est ADMIN.
/// Usage : actions: [AdminDeleteButton(onDelete: () => _deleteItem(id))],
class AdminDeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  final Color? color;

  const AdminDeleteButton({super.key, required this.onDelete, this.color});

  bool get _isAdmin => AuthSession().user?.role == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return const SizedBox.shrink(); // invisible pour le chef

    return IconButton(
      icon: Icon(Icons.delete_outline, color: color ?? Colors.red),
      onPressed: () => _confirm(context),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Cette action est irréversible. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) onDelete();
  }
}
