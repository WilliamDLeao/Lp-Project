-- title: First Fantasy
-- author: Seu Nome
-- desc: Jogo de Aventura
-- script: lua

-- ------------------------------
-- VARIÁVEIS GLOBAIS
-- ------------------------------

-- Variáveis do menu
menu_state = "main"
selected_option = 1
menu_options = {"START GAME", "OPTIONS", "CREDITS", "EXIT"}
title_y = 30
option_spacing = 10

-- Estado do jogo
game_started = false

-- Cores
COLOR_BG = 0
COLOR_TITLE = 15
COLOR_TEXT = 6
COLOR_SELECTED = 11
COLOR_HIGHLIGHT = 14

-- Variáveis para o sistema de paredes
current_wall = 0
was_pressed_last_frame = false 
button_left = { x = 15, y = 68, radius = 6 }
button_right = { x = 215, y = 68, radius = 6 }

-- Variáveis do Monólogo
monologue_active = false
monologue_messages = {}     -- A lista de textos para exibir
current_message_index = 1 -- Qual texto da lista estamos mostrando
current_char_index = 0    -- Quantos caracteres do texto atual estão visíveis
typing_timer = 0
TYPING_SPEED = 2          -- Frames por caractere (menor = mais rápido)


-- ------------------------------
-- FUNÇÃO PRINCIPAL (LOOP)
-- ------------------------------

function TIC()
	cls(COLOR_BG)
	
	if game_started then
		
		-- 1. Só roda a lógica do JOGO se o monólogo NÃO estiver ativo
		if not monologue_active then
			handle_game_logic()
		end
		
		-- 2. O desenho do jogo sempre roda por baixo
		draw_game() 
		
		-- 3. O monólogo atualiza e desenha por cima do jogo
		if monologue_active then
			update_monologue()
			draw_monologue()
		end
		
	else
		-- Lógica do Menu (como estava antes)
		if menu_state == "main" then
			draw_main_menu()
		elseif menu_state == "options" then
			draw_options_menu()
		elseif menu_state == "credits" then
			draw_credits_menu()
		end
		
		handle_input()
	end
end

-- ------------------------------
-- LÓGICA E DESENHO DO JOGO
-- ------------------------------

-- (NOVA FUNÇÃO - Cuida de toda a lógica do jogo)
function handle_game_logic()
	-- Lógica do clique nos botões de navegação
	local mouse_x, mouse_y, left_button = mouse()
	local is_new_click = left_button and not was_pressed_last_frame

	if is_new_click then
		local wall_changed = false
		local old_wall = current_wall -- Salva a parede antiga

		if is_mouse_in_circ(mouse_x, mouse_y, button_left.x, button_left.y, button_left.radius) then
			current_wall = (current_wall - 1 + 4) % 4
			wall_changed = true
		end
		if is_mouse_in_circ(mouse_x, mouse_y, button_right.x, button_right.y, button_right.radius) then
			current_wall = (current_wall + 1) % 4
			wall_changed = true
		end
		
		-- Verifica se a parede mudou e para qual ela foi
		if wall_changed and old_wall ~= current_wall then
			
			-- GATILHO: SE A NOVA PAREDE FOR A 0
			if current_wall == 0 then
				start_monologue({"Bem-vindo de volta a parede 1!", "Este e o segundo texto."})
			
			-- GATILHO: SE A NOVA PAREDE FOR A 1
			elseif current_wall == 1 then
				 start_monologue({"Voce esta na parede 2."})
			end
		end
	end
	
	was_pressed_last_frame = left_button

	-- Verifica se quer voltar ao menu (Tecla ESC)
	if keyp(45) then -- Tecla ESC
		game_started = false
		menu_state = "main"
	end
end

-- (FUNÇÃO ATUALIZADA - Cuida apenas de desenhar o jogo)
function draw_game()
	-- Tela do jogo em execução
	cls(13) -- Fundo azul para o jogo
	
	-- Desenha a parede atual (forma simplificada)
	-- Isso substitui todo o seu "if/elseif"
	map(current_wall * 30, 0, 30, 17, 0, 0)
	
	-- Desenha os botões de navegação
	put_buttons(15)
	
	local mouse_x, mouse_y = mouse()
	hover_buttons(mouse_x, mouse_y)
	
	-- Texto informativo
	print("JOGO INICIADO!", 60, 140, 15, true, 1)
	print("PRESSIONE ESC PARA VOLTAR AO MENU", 20, 160, 15)
end

-- ------------------------------
-- SISTEMA DE MONÓLOGO
-- ------------------------------

-- 1. FUNÇÃO PARA INICIAR O MONÓLOGO
function start_monologue(messages)
	if messages and #messages > 0 then
		monologue_messages = messages
		current_message_index = 1
		current_char_index = 0
		typing_timer = 0
		monologue_active = true
	end
end

-- 2. FUNÇÃO PARA ATUALIZAR A LÓGICA DO MONÓLOGO
function update_monologue()
	if not monologue_active then return end
	
	local message = monologue_messages[current_message_index]
	if not message then monologue_active = false; return end
	
	local total_length = #message
	-- Arredonda para baixo para comparar
	local visible_chars = math.floor(current_char_index) 
	local is_typing = visible_chars < total_length
	
	-- Lógica de "digitação"
	if is_typing then
		typing_timer = typing_timer + 1
		if typing_timer >= TYPING_SPEED then
			current_char_index = current_char_index + 1
			typing_timer = 0
		end
	end
	
	-- Lógica de Input (botão Z)
	if btnp(4) then -- 'Z'
		if is_typing then
			-- Pula a animação
			current_char_index = total_length
		else
			-- Vai para a próxima mensagem
			current_message_index = current_message_index + 1
			if current_message_index > #monologue_messages then
				-- Fim do monólogo
				monologue_active = false
			else
				-- Reseta para a próxima mensagem
				current_char_index = 0
				typing_timer = 0
			end
		end
	end
end

-- 3. FUNÇÃO PARA DESENHAR O MONÓLOGO
function draw_monologue()
	if not monologue_active then return end
	
	-- Desenha a caixa de texto (fundo escuro, borda clara)
	rect(8, 86, 224, 44, 1) -- Fundo (preto)
	rectb(8, 86, 224, 44, 15) -- Borda (branco)
	
	local message = monologue_messages[current_message_index]
	if not message then return end
	
	local visible_chars = math.floor(current_char_index)
	local visible_text = string.sub(message, 1, visible_chars)
	
	-- Imprime o texto com quebra de linha automática
	-- x=12, y=90, cor=15, scale=1, largura_max=216
	print(visible_text, 12, 90, 15, false, 1, 216)
	
	-- Indicador de "próximo" (pisca se o texto terminou)
	if visible_chars == #message and (time() % 30 < 15) then
		print("v", 220, 122, 15) -- Seta 'v' no canto
	end
end


-- ------------------------------
-- SISTEMA DE MENU
-- ------------------------------

function draw_main_menu()
	t=0 -- espacamento p deixar tudp centralizado
	cont = 0 --contador p adequar tudo e deixar corretamente espcado
 
	-- Título
	print("First Fantasy", 50, title_y, 2, true, 2)
	print("First Fantasy", 51, title_y, 4, true, 2)
	
	-- Opções do menu
	for i, option in ipairs(menu_options) do
		local y = 80 + (i * option_spacing)
		local color = COLOR_TEXT
		
		if i == selected_option then
			color = COLOR_SELECTED
			-- Desenha marcador de seleção
			print(">", 80, y, COLOR_HIGHLIGHT)
			print("<", 150, y, COLOR_HIGHLIGHT)
		end
		
		print(option,(90+t), y, color)
		t=t+7
		if t==14 then
			t=t-7
		end
	end
	draw_some_lines()
end

function draw_options_menu() 
	print("CONFIGURACOES", 50, 10, COLOR_TITLE, true, 2)
	print("VOLUME", 50, 40, COLOR_TEXT)
	print("CONTROLES", 50, 50, COLOR_TEXT)
	
	-- Destacar a opção voltar quando selecionada
	if selected_option == 3 then
		print("> VOLTAR <", 50, 120, COLOR_SELECTED)
	else
		print("VOLTAR", 50, 120, COLOR_TEXT)
	end
	
	print("PRESSIONE ESC PARA VOLTAR", 30, 180, 8)
end

function draw_credits_menu()
	print("CREDITOS", 50, 10, COLOR_TITLE, true, 2)
	print("Aperte Z para SAIR", 50, 70, COLOR_TITLE, true, 1)
	print("PROGRAMADOR: VOCE", 50, 40, COLOR_TEXT)
	print("MUSICA: TIC-80", 50, 50, COLOR_TEXT)
	print("ARTE: PIXEL ART", 50, 60, COLOR_TEXT)
end

function handle_input()
	if game_started then return end -- Não processa input do menu se o jogo está rodando
	
	-- Navegação do menu principal
	if menu_state == "main" then
		if btnp(0) then -- Cima
			selected_option = selected_option - 1
			if selected_option < 1 then
				selected_option = #menu_options
			end
		elseif btnp(1) then -- Baixo
			selected_option = selected_option + 1
			if selected_option > #menu_options then
				selected_option = 1
			end
		elseif btnp(4) then -- Enter/Z
			select_menu_option()
		end
	elseif menu_state == "options" then
		-- Navegação simples no menu de opções
		if btnp(0) then -- Cima
			selected_option = 3 -- Vai direto para "Voltar"
		elseif btnp(1) then -- Baixo
			selected_option = 3 -- Vai direto para "Voltar"
		elseif btnp(4) then -- Enter/Z
			if selected_option == 3 then
				menu_state = "main"
				selected_option = 2 -- Volta para OPTIONS no menu principal
			end
		elseif btnp(5) then -- Esc/X
			menu_state = "main"
			selected_option = 2 -- Volta para OPTIONS no menu principal
		end
	elseif menu_state == "credits" then
		if btnp(5) then -- Esc/X
			menu_state = "main"
			selected_option = 3 -- Volta para CREDITS no menu principal
		elseif btnp(4) then -- Enter/Z também volta
			menu_state = "main"
			selected_option = 3 -- Volta para CREDITS no menu principal
		end
	end
end

function select_menu_option()
	if selected_option == 1 then
		-- START GAME
		start_game()
	elseif selected_option == 2 then
		-- OPTIONS
		menu_state = "options"
		selected_option = 3 -- Seleciona "Voltar" no menu de opções
	elseif selected_option == 3 then
		-- CREDITS
		menu_state = "credits"
	elseif selected_option == 4 then
		-- EXIT
		exit_game()
	end
end

function start_game()
	-- Muda o estado para jogo iniciado
	game_started = true
end

function exit_game()
	-- Sai do jogo
	exit()
end

-- ------------------------------
-- FUNÇÕES UTILITÁRIAS
-- ------------------------------

function draw_some_lines()
	circ(2, 20, 20, 2)
	circ(240, 20, 20, 2)
	rectb(5, 5, 230, 130, 4) 	-- Apenas o contorno 		 
end

-- Funções para o sistema de paredes
function is_mouse_in_circ(mx, my, cx, cy, radius)
	local dx = mx - cx
	local dy = my - cy
	return dx*dx + dy*dy <= radius*radius
end

function put_buttons(color)
	circb(button_left.x, button_left.y, button_left.radius, color)
	print("<", button_left.x - 1, button_left.y - 2, color)

	circb(button_right.x, button_right.y, button_right.radius, color)
	print(">", button_right.x - 1, button_right.y - 2, color)
end

function hover_buttons(mx, my)
	if is_mouse_in_circ(mx, my, button_left.x, button_left.y, button_left.radius) then
		circb(button_left.x, button_left.y, button_left.radius, 14)
		print("<", button_left.x - 1, button_left.y - 2, 14)
	end

	if is_mouse_in_circ(mx, my, button_right.x, button_right.y, button_right.radius) then
		circb(button_right.x, button_right.y, button_right.radius, 14)
		print(">", button_right.x - 1, button_right.y - 2, 14)
	end
end