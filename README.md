# Movie Listing App (iOS SwiftUI)

Este é um aplicativo iOS simples construído com SwiftUI que demonstra a listagem de filmes populares obtidos da API do [The Movie Database (TMDb)](https://www.themoviedb.org/documentation/api). O projeto foca em boas práticas de arquitetura, testabilidade e escalabilidade, mesmo para uma funcionalidade básica.

## Funcionalidades

*   Listagem de filmes populares com paginação infinita.
*   Exibição de pôster, título, avaliação e uma breve sinopse para cada filme.
*   Tratamento de estados de carregamento e erro.
*   Atualização da lista ("pull to refresh" implícito ao recarregar).

## Arquitetura e Tomadas de Decisão

O projeto foi estruturado visando clareza, separação de responsabilidades e facilidade de manutenção e expansão futura.

### 1. Padrão de Arquitetura: MVVM (Model-View-ViewModel)

*   **Decisão:** Adotamos o padrão MVVM para separar a lógica de apresentação da interface do usuário.
*   **Justificativa:**
    *   **Testabilidade:** ViewModels são mais fáceis de testar unitariamente, pois não têm dependências diretas da UI.
    *   **Separação de Responsabilidades:** A `View` é responsável apenas pela apresentação e por delegar ações do usuário ao `ViewModel`. O `ViewModel` prepara e fornece os dados para a `View` e lida com a lógica de negócios da UI. O `Model` representa os dados.
    *   **Reatividade:** O uso de `@StateObject` e `@Published` em SwiftUI se encaixa naturalmente com o MVVM, permitindo que a UI reaja automaticamente a mudanças no estado do ViewModel.

### 2. Estrutura de Pastas: Feature-First (Simplificada)

*   **Decisão:** Os arquivos foram organizados primariamente por funcionalidade, com uma pasta `Core` para componentes compartilhados.
    ```
    SimpleMovieApp/
    ├── App/            # Ponto de entrada
    ├── Core/           # Componentes compartilhados (Networking, Models, Erros)
    ├── Features/
    │   └── MovieListing/ # Funcionalidade de Listagem (Views, ViewModels, Repositories)
    └── MovieListViewModelTests/ # Testes
    ```
*   **Justificativa:**
    *   **Escalabilidade:** Mesmo para um app simples, essa estrutura facilita a adição de novas funcionalidades no futuro. Cada nova feature teria sua própria pasta dentro de `Features/`.
    *   **Coesão:** Componentes relacionados a uma mesma funcionalidade (listagem de filmes) estão agrupados, facilitando a navegação e o entendimento.
    *   **Baixo Acoplamento:** A pasta `Core` contém elementos que podem ser reutilizados, enquanto as features tentam ser o mais independentes possível.

### 3. Camada de Rede e Repositório

*   **Serviço de API (`MovieAPIService`):**
    *   **Decisão:** Uma classe dedicada para encapsular todas as chamadas à API do TMDb.
    *   **Justificativa:** Centraliza a lógica de comunicação com a API, tornando-a mais fácil de manter e mockar para testes. Usa `async/await` para chamadas de rede assíncronas.
    *   Utiliza um protocolo (`MovieAPIServiceProtocol`) para permitir injeção de dependência e mocks.

*   **Repositório (`MovieRepository`):**
    *   **Decisão:** Uma camada de abstração entre o ViewModel e as fontes de dados (atualmente, apenas o `MovieAPIService`).
    *   **Justificativa:**
        *   **Escalabilidade para Offline:** Prepara o terreno para futuras implementações de cache local (CoreData, SwiftData, Realm). O ViewModel solicitaria dados ao Repositório, e o Repositório decidiria se busca da API ou do cache, sem que o ViewModel precise saber dessa lógica.
        *   **Single Source of Truth (Futuro):** O Repositório pode se tornar o ponto central para obter dados, gerenciando a sincronização entre dados remotos e locais.
        *   Utiliza um protocolo (`MovieRepositoryProtocol`).

### 4. Gerenciamento de Estado e Reatividade

*   **Decisão:** Utilização de `SwiftUI` com `@StateObject` para o ciclo de vida do `MovieListViewModel` e `@Published` para suas propriedades observáveis.
*   **Justificativa:** Aproveita as ferramentas nativas do SwiftUI para um gerenciamento de estado reativo e eficiente, garantindo que a UI seja atualizada automaticamente quando os dados no ViewModel mudam. A anotação `@MainActor` nos ViewModels garante que as atualizações da UI ocorram na thread principal.

### 5. Tratamento de Erros

*   **Decisão:** Um enum `AppError` customizado para representar diferentes tipos de falhas (rede, parsing, API). O ViewModel expõe um `errorMessage` que a View usa para exibir um alerta.
*   **Justificativa:** Fornece mensagens de erro mais claras e específicas para o usuário e facilita a depuração.

### 6. Testabilidade

*   **Decisão:** Foco em tornar os ViewModels testáveis através da injeção de dependências (usando protocolos para o Repositório e Serviço de API). Mocks (`MockMovieRepository`, `MockMovieAPIService`) são usados nos testes unitários.
*   **Justificativa:** Garante a confiabilidade da lógica de negócios e da apresentação. Testes unitários para o `MovieListViewModel` verificam o carregamento de dados, paginação, e tratamento de estados de sucesso/erro.

### 7. Segurança da Chave de API

*   **Decisão:** A chave de API do TMDb é gerenciada através de um arquivo de configuração (`.xcconfig`) que não é versionado no Git. O valor é injetado no `Info.plist` durante o build e lido no código.
*   **Justificativa:** Evita a exposição da chave de API em repositórios públicos, seguindo uma prática de segurança comum.

### 8. Paginação

*   **Decisão:** Implementada no `MovieListViewModel`, carregando novas páginas de filmes quando o usuário rola a lista e se aproxima do final dos itens atualmente carregados.
*   **Justificativa:** Melhora a performance e a experiência do usuário ao não carregar todos os filmes de uma vez.

### 9. Caching de chamadas em Memória com `NSCache`

*   **Decisão:** Para melhorar a performance e a experiência do usuário ao revisitar páginas de filmes já carregadas, foi implementado um cache em memória utilizando `NSCache` dentro da camada de `MovieRepository`.
*   **Justificativa:**
    *   **Performance:** Reduz significativamente a latência para buscar dados já visualizados, pois evita chamadas de rede repetidas para o mesmo conteúdo dentro de uma mesma sessão de uso do aplicativo.

### 10. Caching de Imagens em Memória

*   **Decisão:** Utilizar `NSCache` (via `ImageCacheService`) e uma `CachedAsyncImageView` customizada para armazenar temporariamente as imagens dos pôsteres dos filmes na memória do dispositivo.
*   **Justificativa Principal:** Melhorar significativamente a **performance da UI e a fluidez da rolagem** na lista de filmes, recarregando imagens já vistas rapidamente e **reduzindo requisições de rede** repetidas durante a mesma sessão do app. `NSCache` gerencia a memória eficientemente.


## Como Executar

1.  Clone o repositório.
2.  Crie um arquivo `APIKeys.xcconfig` na raiz do projeto (ao lado do arquivo `.xcodeproj`).
3.  Adicione a seguinte linha ao `APIKeys.xcconfig`, substituindo `SUA_CHAVE_DE_API_AQUI` pela sua chave do TMDb v3:
    ```xcconfig
    TMDB_API_KEY = SUA_CHAVE_DE_API_AQUI
    ```
4.  Abra o arquivo `.xcodeproj` no Xcode.
5.  Configure o projeto para usar o `APIKeys.xcconfig`:
    *   Selecione o projeto no Navegador de Projetos.
    *   Vá para a aba "Info" do **PROJETO** (não do target).
    *   Em "Configurations", expanda "Debug" e "Release".
    *   Para cada uma, selecione `APIKeys` (o nome do seu arquivo .xcconfig) na coluna "Based on Configuration File".
6.  No `Info.plist` do seu **TARGET**, adicione uma nova linha:
    *   Key: `TMDB_API_KEY`
    *   Type: `String`
    *   Value: `$(TMDB_API_KEY)`
7.  Compile e execute no simulador ou dispositivo.

## Testes

Os testes unitários para o `MovieListViewModel` podem ser encontrados no target de testes (`MovieListViewModelTests`). Eles utilizam mocks para simular as dependências de rede e verificar o comportamento do ViewModel em diferentes cenários.

## Possíveis Melhorias Futuras

*   Tornar o app offline first, acessando primeiro o ambiente local e atualizando com o conteudo online.
*   Tela de detalhes do filme, poderia tambem usar outras apis em conjunto para trazer mais informaçoe sobre o filme, usando concorrencia para melhorar perfomance.
*   Criar pequenos packages desacoplados, por exemplo camada de CORE e NETWORK
*   Extrair as views em componentes menores
*   Funcionalidade de busca de filmes
*   Shimmering enquanto faz o loading das imagens
*   Testes de UI.
*   Acessibilidae 
*   Usar os textos atraves de localizables.
 
