class_name CameraJogo
extends Camera2D
## Câmera que segue a Coveira dentro dos limites da sala (centralizando salas menores que a
## tela) e aplica o tremor e o recuo do Efeitos em pixels inteiros.

const TELA := Vector2(640, 360)
const TREMOR_MAX := 5.0

var _ruido := FastNoiseLite.new()
var _t := 0.0


func _init() -> void:
	# Com interpolação de física ligada, a câmera precisa atualizar no passo de física.
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	_ruido.frequency = 18.0
	position = Vector2(0, -10)


func definir_limites(retangulo: Rect2) -> void:
	var centro := retangulo.get_center()
	# Em salas menores que a tela, os limites se abrem simetricamente (sala centralizada).
	var largura := maxf(retangulo.size.x, TELA.x)
	var altura := maxf(retangulo.size.y + 16.0, TELA.y)
	limit_left = int(floorf(centro.x - largura * 0.5))
	limit_right = int(ceilf(centro.x + largura * 0.5))
	limit_top = int(floorf(centro.y - altura * 0.5 - (16.0 if retangulo.size.y + 16.0 > TELA.y else 0.0)))
	limit_bottom = int(ceilf(centro.y + altura * 0.5))


func _process(delta: float) -> void:
	_t += delta
	var forca := Efeitos.trauma * Efeitos.trauma * TREMOR_MAX
	var tremor := Vector2(_ruido.get_noise_2d(_t * 60.0, 0.0), _ruido.get_noise_2d(0.0, _t * 60.0)) * forca
	offset = (tremor + Efeitos.chute).round()
