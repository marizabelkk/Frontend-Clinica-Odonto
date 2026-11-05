# Odonto UNINASSAU

Aplicativo Flutter para apoiar a rotina de uma clínica odontológica universitária. A interface organiza o acesso por perfil e integra o atendimento a uma API REST.

## Funcionalidades

- Autenticação de usuários e navegação conforme o perfil.
- Busca, cadastro e consulta de pacientes.
- Visualização do prontuário odontológico.
- Início de atendimento e preenchimento da avaliação de Semiologia.
- Painéis para recepção, professores e coordenação.

> A integração de gestão da coordenação ainda está em desenvolvimento. O aplicativo usa a API para autenticação e operações de pacientes e atendimentos.

## Tecnologias

- Flutter e Dart
- Provider para gerenciamento de estado
- Dio para comunicação HTTP
- API REST com autenticação Bearer

## Requisitos

- Flutter instalado e configurado no PATH
- Um dispositivo ou emulador compatível com Flutter
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
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Em um emulador ou aparelho físico, substitua `localhost` pelo endereço que o dispositivo consegue acessar. O aplicativo acrescenta o caminho `/api/v1/` automaticamente.

## Testes

Execute os testes automatizados com:

```bash
flutter test
```

## Estrutura do projeto

```text
lib/
├── core/          # configuração de API, rede e tema
├── data/          # modelos, repositórios e view models
└── views/         # telas e componentes da interface
test/              # testes automatizados
```

## Contribuição

1. Crie uma branch para sua alteração.
2. Faça as mudanças e adicione testes quando necessário.
3. Abra um pull request descrevendo o que foi atualizado.
