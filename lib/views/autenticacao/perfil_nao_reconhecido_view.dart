import 'package:flutter/material.dart';

import '../../models/usuario_model.dart';
import '../../widgets/botao_alternar_tema.dart';

class PerfilNaoReconhecidoView extends StatelessWidget {
  const PerfilNaoReconhecidoView({
    required this.usuario,
    required this.onLogout,
    super.key,
  });

  final UsuarioModel usuario;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Perfil não reconhecido'),
      actions: const [BotaoAlternarTema()],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              usuario.nome,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('O perfil retornado pela API não está definido.'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    ),
  );
}
