class_name MundoTeste
extends Node2D
## Mundo mínimo para testes de simulação: uma sala montada de verdade, a Coveira controlada
## por uma fonte de entrada de teste e os nós de efeitos registrados (para exercitar tudo).

const SALA_ABERTA := "nome: Teste\ntipo: inicio\n---\n####################\n####################\n####################\n#..................#\n#..................#\n#..................#\n#.........@........#\n#..................#\n#..................#\n#..................#\n####################\n"

var sala: Sala
var jogador: Jogador
var entrada := FonteEntrada.new()
var particulas: SistemaParticulas
var numeros: NumerosDano
var ondas: Node2D


static func criar(pai: Node, texto_sala: String = SALA_ABERTA, semente: int = 5) -> MundoTeste:
	Jogo.nova_descida(semente)
	var m := MundoTeste.new()
	pai.add_child(m)
	m._montar(texto_sala, semente)
	return m


func _montar(texto: String, semente: int) -> void:
	var def := DefinicaoSala.de_texto(texto)
	def.id = "teste"
	assert(def.valida(), "; ".join(def.erros))
	sala = ConstrutorSala.construir(def, semente)
	add_child(sala)
	particulas = SistemaParticulas.new()
	numeros = NumerosDano.new()
	ondas = Node2D.new()
	add_child(particulas)
	add_child(numeros)
	add_child(ondas)
	Efeitos.registrar(particulas, sala.manchas, numeros, ondas)
	particulas.manchas = sala.manchas
	jogador = Jogador.new()
	jogador.entrada = entrada
	sala.mundo.add_child(jogador)
	jogador.global_position = sala.posicao_chegada()
	jogador.reset_physics_interpolation()


## Cria um inimigo já ativo (sem animação de surgimento) na posição dada.
func inimigo(tipo: StringName, posicao: Vector2) -> Inimigo:
	var i := FabricaInimigos.criar(tipo)
	i.sala = sala
	i.position = posicao
	sala.mundo.add_child(i)
	i.pular_surgimento()
	return i


func centro() -> Vector2:
	return sala.retangulo().get_center()
