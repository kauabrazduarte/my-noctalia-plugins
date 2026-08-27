# Battery Charge Mode

Plugin nativo do noctalia-shell que mostra e alterna o modo de carga da bateria
no Lenovo IdeaPad Slim 3, integrado com TLP.

## Funcionalidades

- **Bar widget**: ícone (raio para Standard, folha para Long_Life) + % de carga
  ao lado. Clique alterna o modo (pede senha via `pkexec`).
- **Service**: lê o estado real do `conservation_mode` do driver Lenovo a cada
  2 segundos e publica no estado compartilhado do plugin.
- **Control-center shortcut**: tile rápido com label "100%" ou "60%".
- **Detail panel**: status completo com botão de alternar.
- **i18n**: pt-BR e en.

## Modos

- **Standard** — carga até 100%. Use antes de sair de casa / viagem.
- **Long_Life** — carga trava em ~60%. Recomendado quando fica na tomada.

## Instalação

```sh
cp -r battery_mode ~/.config/noctalia/plugins/
```

Depois ative em **Settings → Plugins**.

## Dependências externas

- `tlp` (>= 1.4) — para `tlp fullcharge` / `tlp start`
- `pkexec` (polkit) — para a caixa de autenticação gráfica
- `fish` com as funções `bat-cheia` e `bat-poupar` em
  `~/.config/fish/functions/` (opcional, usado como fallback)

O sysfs `conservation_mode` do driver `ideapad_laptop` precisa estar exposto:

```sh
cat /sys/devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/conservation_mode
```

Se esse caminho não existir, o caminho do sysfs é específico do modelo — edite
`service.luau` para apontar pro caminho certo do seu hardware.

## Uso

- Adicione o widget **battery_mode** à barra pelo Add-widget picker.
- Clique no widget para alternar entre Standard (100%) e Long_Life (60%).
- Uma janela do polkit pedirá a senha root.

## Licença

MIT
