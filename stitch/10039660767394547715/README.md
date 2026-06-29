# Stitch Fetch Report

Project ID: `10039660767394547715`

Screens:
- `1ed4dd6d22cd49a0ab6a196dc16005d0`
- `02ee4c4a570a40248eda63341ef25173`
- `73ba01366fdf4b1ebaf587f00191c076`
- `4b8868ce42604253ad4abf10c59e1954`

## Resultado
Nao foi possivel baixar code/images apenas com IDs.

Tentativas via `curl -L`:
- URLs `chatgpt.com/stitch/...`: `403`
- URLs `api.openai.com/v1/stitch/...`: `404`

Detalhes completos:
- `urls.txt`
- `curl_attempts.log`

## Proximo passo para destravar
Fornecer os hosted URLs de export (code/images) gerados pelo Stitch para cada screen.
Com os links, basta rodar:

```bash
curl -L "<hosted-url>" -o "<arquivo-destino>"
```
