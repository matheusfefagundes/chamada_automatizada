Chamada Automatizada

- Aplicativo Flutter para automatização do registo de presenças em sala de aula ou eventos, utilizando geolocalização e um desafio de vivacidade.

📝 Descrição
- Este projeto visa simplificar o processo de chamada, eliminando a necessidade de intervenção manual do professor. O aplicativo executa rodadas de verificação de presença em intervalos configuráveis. Para confirmar a presença, o aluno precisa estar dentro de uma área geográfica pré-definida e responder a um simples desafio ("liveness check") apresentado no ecrã dentro de um tempo limite.

✨ Funcionalidades Principais
- Cadastro Inicial: Permite ao aluno registar os seus dados básicos (nome, matrícula, turma) na primeira utilização.
- Agendador Automático: Executa rodadas de chamada em intervalos e número de vezes configuráveis.
- Verificação por Geolocalização: Confirma se o dispositivo do aluno está dentro do raio geográfico permitido.
- Desafio de Vivacidade: Apresenta um botão que o aluno deve pressionar dentro de um curto período para confirmar que está presente e atento.
- Rodada Manual: Permite ao aluno forçar uma verificação de presença a qualquer momento.
- Dashboard: Exibe o status atual da chamada, informações do aluno, a hora da próxima rodada e o resultado da última verificação.
- Histórico Diário: Lista todas as rodadas de chamada do dia com o respetivo resultado (Presente, Ausente, Fora do Local, Erro).
- Exportação CSV: Permite exportar o histórico de presenças do dia para um ficheiro CSV e partilhá-lo via WhatsApp, E-mail, etc.
- Sincronização Cloud: Salva os registos de presença numa base de dados externa (Firebase Firestore).
- Configurações: Permite ajustar o número de rodadas e o intervalo entre elas, além de ativar/desativar o agendador.

🚀 Como Começar
- Estas instruções permitirão que obtenha uma cópia do projeto em execução na sua máquina local para fins de desenvolvimento e teste.

Pré-requisitos
- Flutter SDK (Canal Stable recomendado)
- Um editor de código como VS Code (recomendado)
- Um emulador/simulador configurado (Android Studio recomendado).

Instalação e Execução

Clone o repositório:
- git clone <https://github.com/matheusfefagundes/chamada_automatizada.git>
- cd chamada_automatizada

Instale as dependências:
- flutter pub get

Executando em emulador (Android Studio):
- flutter run

- Observação: Para testar a funcionalidade de localização no emulador Android, certifique-se de definir a localização do emulador para as coordenadas alvo nas configurações estendidas do emulador.
- Permissões: Conceda as permissões de localização quando solicitado pelo aplicativo.

Executando em Dispositivo Físico (Celular Android) :
- Ative o Modo de Desenvolvedor no seu celular (Vá em Configurações > Sobre o telefone e toque 7 vezes em "Número da versão" ou "Build number").
- Nas Opções do Desenvolvedor, ative a Depuração USB.
- Conecte o celular ao computador via cabo USB. Aceite a solicitação de depuração na tela do celular.

Execute o comando no terminal:
- flutter run

⚠️ Importante: Testando Fora do Local Padrão
- O aplicativo vem configurado com coordenadas geográficas fixas (hardcoded) para uma localização específica (ex: Faculdade).
- Se você estiver testando o aplicativo em sua casa ou em outro local, você precisará alterar as coordenadas no código para a sua localização atual, caso contrário, o status será sempre "Fora do Local".
- Obtenha sua latitude e longitude atuais (você pode usar o Google Maps).
- Abra o arquivo: lib/services/attendance_service.dart.
- Localize as seguintes linhas (aprox. linha 22):
    final double _targetLatitude = -26.304309480393407; 
    final double _targetLongitude = -48.851039224536311;
- Substitua os valores pelos da sua localização atual.
- Salve o arquivo e reinicie o aplicativo (Hot Restart ou Re-run).

🏗️ Estrutura do Projeto (simplificada)
lib/
├── main.dart             # Ponto de entrada da aplicação
├── models/               # Definições das classes de dados (Student, AppSettings, AttendanceRecord)
├── screens/              # Widgets que representam as telas da UI (Dashboard, History, Settings, etc.)
└── services/             # Lógica de negócio e acesso a serviços (AttendanceService, SettingsService)

⚙️ Configuração
- Localização Alvo: As coordenadas geográficas (_targetLatitude, _targetLongitude) e o raio máximo (_maxDistanceInMeters) estão definidos diretamente no ficheiro lib/services/attendance_service.dart.
- Permissões: As permissões de localização necessárias já estão declaradas nos ficheiros android/app/src/main/AndroidManifest.xml e ios/Runner/Info.plist.

📦 Dependências Principais
As seguintes bibliotecas são utilizadas no projeto (referência pubspec.yaml):
- provider: Gerenciamento de estado eficiente e injeção de dependência.
- geolocator: Acesso aos serviços de localização do dispositivo para verificar a presença na área alvo.
- shared_preferences: Persistência de dados local simples (perfil do aluno, configurações, histórico local).
- firebase_core & cloud_firestore: Integração com o Firebase para salvar os registos de presença na nuvem em tempo real.
- csv: Geração de ficheiros CSV para exportação dos dados de presença.
- path_provider: Acesso ao sistema de ficheiros do dispositivo para salvar o CSV gerado.
- share_plus: Funcionalidade para partilhar o ficheiro CSV gerado com outras aplicações (WhatsApp, E-mail, etc.).
- intl: Formatação de datas e números para exibição na UI e nos relatórios.
- cupertino_icons: Conjunto de ícones padrão do estilo iOS.