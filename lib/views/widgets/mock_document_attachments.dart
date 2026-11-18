import 'package:flutter/material.dart';

class MockDocumentAttachments extends StatefulWidget {
  const MockDocumentAttachments({super.key});

  @override
  State<MockDocumentAttachments> createState() =>
      _MockDocumentAttachmentsState();
}

class _MockDocumentAttachmentsState extends State<MockDocumentAttachments> {
  final List<String> _files = [];
  static const _examples = [
    'Radiografia panorâmica · exemplo.jpg',
    'Radiografia periapical · exemplo.png',
    'Exame clínico · exemplo.pdf',
    'Foto intraoral · exemplo.jpg',
  ];

  Future<void> _selectExample() async {
    final available = _examples
        .where((name) => !_files.contains(name))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os exemplos já foram selecionados.'),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Selecionar arquivo de demonstração'),
              subtitle: Text('Nenhum arquivo real será enviado.'),
            ),
            for (final name in available)
              ListTile(
                leading: Icon(
                  name.endsWith('.pdf')
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(name),
                onTap: () => Navigator.pop(context, name),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _files.add(selected));
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exames e anexos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'A seleção é simulada. Arquivos reais e envio para armazenamento ainda dependem de integração com a API.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _selectExample,
            icon: const Icon(Icons.attach_file),
            label: const Text('Simular seleção de arquivo ou foto'),
          ),
          for (final file in _files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                file.endsWith('.pdf')
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
              ),
              title: Text(file),
              subtitle: const Text('Exemplo local · não enviado'),
              trailing: IconButton(
                tooltip: 'Remover exemplo',
                onPressed: () => setState(() => _files.remove(file)),
                icon: const Icon(Icons.close),
              ),
            ),
        ],
      ),
    ),
  );
}
