class_name CasoTeste
extends Node
## Base dos testes. Cada método que começa com `teste_` é executado pelo executor.
## Métodos podem usar `await` (para esperar quadros de física, por exemplo).

var falhas: Array[String] = []
var afirmacoes := 0
## Trechos de mensagens de erro que este teste provoca de propósito.
var _erros_esperados: Array[String] = []


## Declara que o teste vai provocar um erro do motor contendo `trecho` (não conta como falha).
func esperar_erro(trecho: String) -> void:
	_erros_esperados.append(trecho)


func erro_esperado(mensagem: String) -> bool:
	for trecho in _erros_esperados:
		if mensagem.contains(trecho):
			return true
	return false


func antes_de_cada() -> void:
	pass


func depois_de_cada() -> void:
	pass


func afirmar(condicao: bool, mensagem: String = "condição falsa") -> void:
	afirmacoes += 1
	if not condicao:
		falhas.append(mensagem)


func afirmar_igual(obtido: Variant, esperado: Variant, mensagem: String = "") -> void:
	afirmacoes += 1
	if typeof(obtido) != typeof(esperado) and not (typeof(obtido) in [TYPE_INT, TYPE_FLOAT] and typeof(esperado) in [TYPE_INT, TYPE_FLOAT]):
		falhas.append("%s — esperado %s (%s), obtido %s (%s)" % [mensagem, esperado, type_string(typeof(esperado)), obtido, type_string(typeof(obtido))])
	elif obtido != esperado:
		falhas.append("%s — esperado %s, obtido %s" % [mensagem, esperado, obtido])


func afirmar_proximo(obtido: float, esperado: float, tolerancia: float, mensagem: String = "") -> void:
	afirmacoes += 1
	if absf(obtido - esperado) > tolerancia:
		falhas.append("%s — esperado %.3f ± %.3f, obtido %.3f" % [mensagem, esperado, tolerancia, obtido])


## Espera N quadros de física.
func quadros(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
