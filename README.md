# Odonto UNINASSAU

Aplicativo Flutter para apoiar a rotina de uma clínica odontológica universitária. A interface organiza o acesso por perfil e integra o atendimento a uma API REST.

## Funcionalidades

- Autenticação de usuários e navegação conforme o perfil.
- Busca, cadastro e consulta de pacientes.
- Visualização do prontuário odontológico.
- Início de atendimento e preenchimento da avaliação de Semiologia.
- Odontograma interativo (numeração FDI): toque no dente, veja e registre, edite ou exclua defeitos.
- Recuperação de senha por e-mail (código de 6 dígitos).
- Modo escuro/claro em todas as telas (botão na barra superior; a escolha é lembrada).
- Painéis para recepção, professores e coordenação.

> A integração de gestão da coordenação ainda está em desenvolvimento. O aplicativo usa a API para autenticação e operações de pacientes e atendimentos.

## Tecnologias

- Flutter e Dart
- Provider para gerenciamento de estado
- Dio para comunicação HTTP
- API REST com autenticação Bearer

## Requisitos

- Flutter 3.44 ou superior (Dart 3.12 ou superior) configurado no PATH
- Chrome ou outro dispositivo/emulador compatível com Flutter
- API da clínica disponível para os fluxos que dependem do servidor

Confira sua instalação com:

```bash
flutter doctor
```

## Como executar

Clone o repositório e instale as dependências:

```bash
git clone https://github.com/marizabelkk/Frontend-Clinica-Odonto.git
cd Frontend-Clinica-Odonto
flutter pub get
```

Por padrão, o app usa `http://localhost:8000` como endereço da API. Para informar outro host, passe `API_BASE_URL` na execução:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Para testar login e operações integradas, inicie a API em outro terminal. Em um emulador ou aparelho físico, substitua `localhost` pelo endereço que o dispositivo consegue acessar. O aplicativo acrescenta o caminho `/api/v1/` automaticamente.

### Contas de teste

Com o backend rodando (`python run.py` cria as contas sozinho), em builds de **debug** a tela de login mostra atalhos que preenchem os campos:

| Perfil | E-mail | Senha |
|---|---|---|
| Aluno | `aluno@uninassau.edu.br` | `aluno123` |
| Professor | `professor@uninassau.edu.br` | `professor123` |
| Recepção | `recepcao@uninassau.edu.br` | `recepcao123` |
| Coordenadora (Admin) | `coordenadora@uninassau.edu.br` | `admin123` |

> Emulador Android: use `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.

### Odontograma

Abra pela seção **7 · Odontograma** da ficha de semiologia (aluno, com o atendimento em andamento: adiciona, edita e exclui defeitos) ou por **Ver odontograma** no prontuário do paciente (somente consulta). A imagem fica em `assets/images/odontograma.jpg`; as regiões clicáveis de cada dente estão em `lib/views/odontograma/tooth_map.dart`.

## Testes

Execute os testes automatizados com:

```bash
flutter test
```

## Estrutura do projeto

```text
lib/
├── core/          # configuração de API, rede, tema e armazenamento local
├── data/          # modelos, repositórios e view models
└── views/         # telas e componentes da interface
test/              # testes automatizados
```

## Contribuição

1. Crie uma branch para sua alteração.
2. Faça as mudanças e adicione testes quando necessário.
3. Abra um pull request descrevendo o que foi atualizado.
