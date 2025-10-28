Chamada Automatizada

- Aplicativo Flutter para automatização do registo de presenças em sala de aula ou eventos, utilizando geolocalização e um desafio de vivacidade.

📝 Descrição
- Este projeto visa simplificar o processo de chamada, eliminando a necessidade de intervenção manual do professor. O aplicativo executa rodadas de verificação de presença em intervalos configuráveis. Para confirmar a presença, o aluno precisa estar dentro de uma área geográfica pré-definida e responder a um simples desafio ("liveness check") apresentado no ecrã dentro de um tempo limite.

✨ Funcionalidades Principais
- Cadastro Inicial: Permite ao aluno registar os seus dados básicos (nome, matrícula, turma) na primeira utilização.
- Agendador Automático: Executa rodadas de chamada em intervalos e número de vezes configuráveis.
- Verificação por Geolocalização: Confirma se o dispositivo do aluno está dentro do raio geográfico permitido (hardcoded para a área da faculdade em Joinville).
- Desafio de Vivacidade: Apresenta um botão que o aluno deve pressionar dentro de um curto período para confirmar que está presente e atento.
- Rodada Manual: Permite ao aluno forçar uma verificação de presença a qualquer momento.
- Dashboard: Exibe o status atual da chamada, informações do aluno, a hora da próxima rodada e o resultado da última verificação.
- Histórico Diário: Lista todas as rodadas de chamada do dia com o respetivo resultado (Presente, Ausente, Fora do Local, Erro).
- Exportação CSV: Permite exportar o histórico de presenças do dia para um ficheiro CSV.
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

Execute o aplicativo:
- flutter run

- Observação: Para testar a funcionalidade de localização no emulador Android, certifique-se de definir a localização do emulador para as coordenadas alvo (Latitude: -26.304309480393407, Longitude: -48.851039224536311) ou uma localização próxima, dentro do raio de 1km. (Ver lib/services/attendance_service.dart).
- Permissões: Conceda as permissões de localização quando solicitado pelo aplicativo.

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
- provider: Para gestão de estado.
- shared_preferences: Para persistência local simples (dados do aluno, configurações).
- geolocator: Para obter a localização do dispositivo.
- csv: Para gerar o ficheiro de exportação CSV.
- path_provider: Para encontrar o diretório correto para salvar o ficheiro CSV.