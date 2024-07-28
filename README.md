# Receitas

## Comandos que ajudam

```shell
# cria arquivo de configuração
ansible-config init --disable > ansible.cfg

# executa modulo ping
ansible myhosts -m ping -i inventory.yml

# executa playbook especifico
ansible-playbook facts.yaml -i inventory.yml

# adiciona variáveis extras
ansible-playbook facts.yaml -i inventory.yml --extra-vars "{\"ansible_user\":\"azureadmin\"}"
```

## Configuração

Arquivo ansible.cfg pode se encontrar no diretório local onde o comando `ansible`
vai rodar, pode estar dentro do diretório (linux) `/etc/ansible`.

Exemplo de configuração da chave SSH:

```ini
[defaults]
private_key_file=minhachaveprivada.pem
host_key_checking=False
```

Pode também passar a chave privada usado argumento na linha de command:

```shell
ansible --private-key minhachaveprivada.pem ......
```

## Inventário

Exemplo para executar módulos na máquina local, use invetário abaixo:

```ini
[all]
localhost   ansible_connection=local
```

Exemplo simples:

```ini
[web]
web1.example.com
web2.example.com

[db]
db1.example.com
db2.example.com
db3.example.com
```

Exemplo com regex:

```ini
[web]
web[1:10].example.com

[db]
db[1:3].example.com
```

Exemplo Yaml:

```yaml
web:
  hosts:
    web1.example.com:
    web2.example.com:
db:
  hosts:
    db1.example.com:
    db2.example.com:
    db2.example.com:
linux:
  children:
    web:
    db:
```

## Arquivos de variáveis

As variáveis tem precedências e precisam de muito cuidado pois pode trazer uma
complexidade muito grande.

```yaml
---
ansible_user: azureadmin
administrator: tmoreira
idioma: pt_BR
curso: IAC
```

Veja sempre a ordem de precedência para não se perder em variáveis.

## Playbooks

Playbooks são tarefas que são executadas em um ou mais hosts.

```yaml
- hosts: myhosts
  become: yes
  tasks:
    - name: instala Nginx
      apt: name=nginx state=latest
```

Melhorando o script acima:

```yaml
- hosts: myhosts
  become: yes
  tasks:
    - name: atualiza cache
      apt: update_cache=yes

    - name: instala Nginx
      apt: name=nginx state=latest
```

Podemos melhorar ainda mais...

```yaml
- hosts: myhosts
  become: yes
  tasks:
    - name: atualiza cache
      apt: update_cache=yes

    - name: instala Nginx
      apt: name=nginx state=latest

      notify:
        - reinicia nginx

  handlers:
    - name: reinicia nginx
      service: name=nginx state=reloaded
```

Adicionando um template:

```yaml
- name: Cria arquivo "index.html" com conteudo template
  template:
    src: "nginx.html.j2"
    dest: /var/www/html/index.html
    mode: 0644
```

Dica pra ir mais rápido:

```yaml
- hosts: myhosts
  gather_facts: false
```

Condicionais:

```yaml
- name: inclui tarefa se a variável hostvar estiver definida
  ansible.builtin.include_tasks: "{{ hostvar }}.yaml"
  when: hostvar is defined
```

Lista de items:

```yaml
- name: instale meus pacotes essenciais
  ansible.builtin.apt:
    pkg:
      - neovim
      - nginx
      - python3-devel
```

### Referências

[Módulo APT](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)
[Módulo DNF](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/dnf_module.html#ansible-collections-ansible-builtin-dnf-module)

## Roles (reusabilidade)
