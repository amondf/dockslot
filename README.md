# DockSlot

App nativo para macOS (Apple Silicon) que adiciona, em qualquer posição do Dock, o mesmo separador que o sistema mostra entre os apps e as pastas.

> Projeto em desenvolvimento. O ajuste fino da linha ainda está sendo validado no Dock real.

## Como funciona

O macOS não permite criar outro separador nativo sem injetar código no Dock, o que exigiria desligar o SIP. O DockSlot chega ao mesmo resultado em duas partes:

1. **Vaga real no Dock.** Adiciona um `small-spacer-tile` às preferências do Dock. A vaga é estreita e pode ser arrastada como qualquer item.
2. **Linha sobre a vaga.** Desenha, numa janela transparente que deixa os cliques passarem, uma linha com as medidas do separador nativo. A posição vem da Accessibility API.

## Requisitos

- Mac com Apple Silicon
- macOS 14 ou mais recente
- Xcode, para compilar
- Permissão de Acessibilidade, para localizar as vagas no Dock

## Compilar e abrir

```bash
./scripts/build.sh
```

```bash
open dist/DockSlot.app
```

Na primeira abertura, ative o DockSlot em **Ajustes do Sistema › Privacidade e Segurança › Acessibilidade**.

O app é assinado localmente (ad-hoc). Cada nova compilação gera uma assinatura diferente, e por isso a permissão precisa ser concedida de novo. Se o DockSlot já aparecer ativado na lista e a linha não surgir, limpe a entrada antiga e abra o app outra vez:

```bash
tccutil reset Accessibility io.github.amondf.dockslot
```

## Uso

O ícone do DockSlot fica na barra de menus:

- **Adicionar separador:** escolha depois de qual item ele deve entrar.
- **Remover separador** e **Remover todos:** tiram as vagas do Dock.
- **Abrir ao iniciar sessão:** mantém as linhas visíveis depois de reiniciar o Mac.

Adicionar ou remover um separador reinicia o Dock por um instante. Depois disso, você também pode arrastar a vaga pelo próprio Dock.

Também há comandos de terminal:

```bash
dist/DockSlot.app/Contents/MacOS/DockSlot list
```

```bash
dist/DockSlot.app/Contents/MacOS/DockSlot add 3
```

```bash
dist/DockSlot.app/Contents/MacOS/DockSlot remove 3
```

```bash
dist/DockSlot.app/Contents/MacOS/DockSlot clear
```

## Bom saber

- Ao arrastar uma vaga, a linha acompanha o cursor até você soltar.
- Se o DockSlot for fechado, as vagas continuam no Dock, mas ficam sem a linha.
- Todo espaçador do Dock recebe uma linha, inclusive os criados por outros meios.
- Antes de cada alteração, a lista anterior é salva em `~/Library/Application Support/DockSlot/Backups`.

## Ajustes da linha

```bash
defaults write io.github.amondf.dockslot lineOpacityLight -float 0.39
```

As chaves disponíveis são `lineOpacityLight`, `lineOpacityDark`, `lineThickness` e `lineLengthRatio`.

## Licença

[MIT](LICENSE)
