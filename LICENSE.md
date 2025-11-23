APPGEAR / WEBAPP IA – LICENÇA PROPRIETÁRIA v0

VERSÃO: 0
DATA: 20/11/2025
TITULAR: PAULO SÉRGIO SANTOS LIMA
CNPJ/ID: 364.694.488-95
CONTATO: eu.plima@outlook.com.br

1. OBJETO

1.1. Este instrumento ("LICENÇA") regula o uso do código-fonte, artefatos, documentações, scripts de automação, manifests, modelos de infraestrutura e demais ativos de software relacionados à plataforma APPGEAR / WEBAPP IA (coletivamente, o "SOFTWARE"), desenvolvidos e detidos pelo TITULAR.

1.2. Esta LICENÇA se aplica a todos os arquivos deste repositório e de repositórios correlatos indicados como parte da "Arquitetura AppGear", exceto quando um arquivo contiver de forma explícita outra licença aplicável.

1.3. Esta LICENÇA não substitui contratos comerciais, termos de serviço ou acordos específicos celebrados entre o TITULAR e terceiros ("CONTRATOS COMERCIAIS"). Em caso de conflito entre esta LICENÇA e um CONTRATO COMERCIAL, prevalecerá o CONTRATO COMERCIAL.

2. PROPRIEDADE INTELECTUAL

2.1. O SOFTWARE, em todas as suas partes originais, incluindo, mas não se limitando a:
     (a) código-fonte, templates, manifests, helm charts, kustomizations, pipelines e scripts;
     (b) documentação técnica e diagramas de arquitetura;
     (c) modelos de dados, convenções de nomenclatura, módulos 00–16 de desenvolvimento;
     (d) artefatos de UI, fluxos de IA, prompts, políticas e automações,
é protegido por leis de direitos autorais, propriedade intelectual e tratados internacionais, sendo de titularidade exclusiva do TITULAR, exceto onde explicitamente indicado em contrário.

2.2. Nenhuma disposição desta LICENÇA deve ser interpretada como transferência de propriedade intelectual ao usuário. É concedido apenas um direito de uso limitado, não exclusivo e intransferível, conforme descrito na Seção 3.

3. CONCESSÃO DE LICENÇA (USO AUTORIZADO)

3.1. Sujeito ao cumprimento integral desta LICENÇA e dos CONTRATOS COMERCIAIS aplicáveis, o TITULAR concede ao usuário ("LICENCIADO") uma licença:
     (a) limitada;
     (b) não exclusiva;
     (c) intransferível;
     (d) revogável;
para instalar, configurar e executar o SOFTWARE, exclusivamente para:
     (i) desenvolvimento, testes, operação e manutenção de ambientes que utilizem a plataforma APPGEAR / WEBAPP IA; e
     (ii) fins internos do LICENCIADO ou do cliente final identificado em CONTRATO COMERCIAL.

3.2. É vedado qualquer uso do SOFTWARE fora do escopo contratado ou desta LICENÇA, incluindo, sem limitação:
     (a) uso por terceiros não autorizados;
     (b) prestação de serviços concorrentes baseados em cópia substancial do SOFTWARE;
     (c) revenda, sublicenciamento ou cessão do SOFTWARE sem autorização expressa e escrita do TITULAR.

4. RESTRIÇÕES EXPRESSAS

4.1. Sem prejuízo de outras restrições previstas em lei, o LICENCIADO NÃO PODE, salvo autorização expressa e escrita do TITULAR:

     (a) copiar, reproduzir ou distribuir o SOFTWARE, total ou parcialmente, para qualquer fim que não seja estritamente necessário ao seu uso autorizado;
     (b) publicar, disponibilizar ou expor o SOFTWARE em repositórios públicos, fóruns, marketplaces ou quaisquer meios que permitam o acesso não autorizado a código, manifests ou documentação proprietária;
     (c) modificar, adaptar, traduzir, fazer engenharia reversa, descompilar, desmontar ou de qualquer forma tentar obter o código-fonte de partes do SOFTWARE que não foram disponibilizadas como tal;
     (d) remover, ocultar ou alterar avisos de direitos autorais, marcas, logotipos, avisos de confidencialidade ou quaisquer notas de propriedade incluídas no SOFTWARE ou na sua documentação;
     (e) utilizar o SOFTWARE para desenvolver, treinar ou auxiliar na construção de produtos/serviços concorrentes que repliquem substancialmente a arquitetura, os fluxos ou as funcionalidades centrais da plataforma APPGEAR / WEBAPP IA;
     (f) utilizar o SOFTWARE em violação à legislação aplicável, incluindo, mas não se limitando a, normas de proteção de dados, privacidade, segurança da informação e propriedade intelectual.

4.2. Qualquer uso não autorizado do SOFTWARE constituirá infração contratual e violação de direitos de propriedade intelectual, sujeitando o infrator às sanções civis, administrativas e criminais cabíveis.

5. COMPONENTES DE TERCEIROS E MICROSSERVIÇOS

5.1. A plataforma APPGEAR / WEBAPP IA integra e orquestra diversos componentes de terceiros, tais como, a título exemplificativo: Traefik, Istio, Keycloak, midPoint, Vault, OpenFGA, OPA, Falco, Ceph, Postgres/PostGIS, Redis, Qdrant, RabbitMQ, Redpanda, Meilisearch, Backstage, Tailscale, n8n, Flowise, LiteLLM, Directus, Appsmith, Metabase, Airbyte, JupyterHub, MLflow, ThingsBoard, Robocorp, LitmusChaos, entre outros.

5.2. Esses componentes de terceiros podem ser:
     (a) distribuídos juntamente com o SOFTWARE; ou
     (b) referenciados como dependências a serem obtidas diretamente de seus respectivos mantenedores.

5.3. Cada um desses componentes de terceiros é licenciado sob a respectiva licença de seu autor (por exemplo, MIT, Apache-2.0, AGPL, GPL ou outra), a qual:
     (a) permanece plenamente vigente e inalterada; e
     (b) prevalece exclusivamente sobre o uso e a redistribuição daquele componente específico.

5.4. Esta LICENÇA:
     (a) NÃO modifica, restringe ou amplia os direitos concedidos por licenças open source ou proprietárias de terceiros;
     (b) NÃO concede quaisquer direitos adicionais sobre o código-fonte de tais componentes além dos já previstos em suas próprias licenças;
     (c) NÃO cria qualquer vínculo de copyleft adicional ao SOFTWARE, exceto se explicitamente declarado em arquivos de licença específicos.

5.5. O LICENCIADO é integralmente responsável por:
     (a) revisar e cumprir as licenças dos componentes de terceiros utilizados;
     (b) manter, quando aplicável, um inventário/SBOM das dependências de cada implantação;
     (c) observar obrigações de atribuição, disponibilização de código-fonte, avisos de copyright ou demais exigências previstas nas licenças desses componentes.

5.6. Recomenda-se a consulta a arquivos auxiliares como `THIRD_PARTY_LICENSES`, `NOTICE` ou equivalentes, quando existentes, que consolidam referências às licenças de componentes de terceiros.

6. CONFIDENCIALIDADE

6.1. O SOFTWARE e sua documentação podem conter informações técnicas, de negócio e de arquitetura classificadas como confidenciais. O LICENCIADO compromete-se a:
     (a) tratar tais informações como confidenciais;
     (b) não divulgá-las a terceiros, exceto quando estritamente necessário para o uso autorizado do SOFTWARE e sujeito a obrigações de confidencialidade equivalentes.

6.2. A confidencialidade aqui prevista complementa, e não substitui, quaisquer obrigações de confidencialidade estabelecidas em CONTRATOS COMERCIAIS.

7. SUPORTE, ATUALIZAÇÕES E MODIFICAÇÕES

7.1. Esta LICENÇA, por si só, não garante suporte técnico, correções, atualizações ou novas versões do SOFTWARE. Tais serviços, quando previstos, serão regidos por CONTRATOS COMERCIAIS específicos.

7.2. O TITULAR poderá, a seu exclusivo critério:
     (a) modificar o SOFTWARE;
     (b) descontinuar partes ou a totalidade do SOFTWARE;
     (c) lançar novas versões sob condições de licença distintas,
sem prejuízo dos direitos mínimos já concedidos ao LICENCIADO nos CONTRATOS COMERCIAIS vigentes.

8. PRAZO E RESCISÃO

8.1. A presente LICENÇA permanece em vigor:
     (a) enquanto houver CONTRATO COMERCIAL vigente entre o TITULAR e o LICENCIADO que a incorpore; ou
     (b) enquanto o LICENCIADO observar fielmente todos os seus termos, na hipótese de uso concedido a título experimental ou gratuito.

8.2. A LICENÇA será automaticamente rescindida, sem necessidade de notificação prévia, se o LICENCIADO:
     (a) violar qualquer obrigação desta LICENÇA e não sanar a infração nos prazos eventualmente previstos em CONTRATO COMERCIAL; ou
     (b) utilizar o SOFTWARE de forma contrária à lei, à boa-fé ou em prejuízo do TITULAR.

8.3. Em caso de rescisão:
     (a) o LICENCIADO deverá cessar imediatamente todo uso do SOFTWARE;
     (b) remover, quando tecnicamente possível, cópias do SOFTWARE de seus ambientes;
     (c) manter apenas os registros e evidências cuja retenção seja exigida por lei ou por obrigações contratuais com terceiros.

9. AUSÊNCIA DE GARANTIAS

9.1. Salvo se expressamente previsto em CONTRATO COMERCIAL, o SOFTWARE é fornecido "NO ESTADO EM QUE SE ENCONTRA", sem garantias de qualquer natureza, expressas ou implícitas, incluindo, sem limitação:
     (a) adequação a um propósito específico;
     (b) ausência de falhas, vulnerabilidades ou interrupções;
     (c) compatibilidade com ambientes específicos de hardware, software ou nuvem.

9.2. O LICENCIADO é responsável por:
     (a) validar o SOFTWARE em seus próprios ambientes;
     (b) implementar medidas de segurança e continuidade de negócio compatíveis com seu grau de criticidade;
     (c) configurar e operar o SOFTWARE em conformidade com o Contrato de Arquitetura e com as melhores práticas de mercado.

10. LIMITAÇÃO DE RESPONSABILIDADE

10.1. Na máxima extensão permitida pela legislação aplicável, o TITULAR não será responsável por danos indiretos, especiais, incidentais, consequenciais, perda de lucros, perda de dados, interrupção de negócios ou quaisquer outros prejuízos decorrentes do uso ou da impossibilidade de uso do SOFTWARE pelo LICENCIADO ou por terceiros.

10.2. Quando houver CONTRATO COMERCIAL estabelecendo limites de responsabilidade, esses limites prevalecerão sobre a presente cláusula, complementando-a.

11. DISPOSIÇÕES GERAIS

11.1. A eventual tolerância a descumprimento de qualquer cláusula desta LICENÇA não importará em renúncia de direito, constituindo mera liberalidade.

11.2. Se qualquer disposição desta LICENÇA for considerada inválida ou inexequível, as demais permanecerão válidas e em pleno vigor.

11.3. Esta LICENÇA poderá ser atualizada pelo TITULAR para refletir mudanças no Contrato de Arquitetura, em legislação aplicável ou em políticas de produto. Versões atualizadas devem ser identificadas por número de versão e data.

11.4. A lei aplicável e o foro competente para dirimir conflitos oriundos desta LICENÇA poderão ser definidos em CONTRATO COMERCIAL específico. Na ausência de definição diversa, aplicar-se-á a legislação brasileira e o foro da comarca do domicílio do TITULAR.

---

© 2025-2025 APPGEAR. Todos os direitos reservados.
APPGEAR / WEBAPP IA é marca e plataforma proprietária do TITULAR ou de seus licenciadores.
