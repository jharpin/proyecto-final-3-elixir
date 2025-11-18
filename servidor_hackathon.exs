# servidor_hackathon.exs
# SERVIDOR CENTRAL DE LA HACKATHON CODE4FUTURE

Code.require_file("domain/participante.ex", __DIR__)
Code.require_file("domain/equipo.ex", __DIR__)
Code.require_file("domain/proyecto.ex", __DIR__)
Code.require_file("domain/mentor.ex", __DIR__)

Code.require_file("adapters/almacenamiento.ex", __DIR__)
Code.require_file("adapters/procesador_comandos.ex", __DIR__)

Code.require_file("servicios/servicio_participantes.ex", __DIR__)
Code.require_file("servicios/servicio_equipos.ex", __DIR__)
Code.require_file("servicios/servicio_proyectos.ex", __DIR__)
Code.require_file("servicios/servicio_mentoria.ex", __DIR__)

defmodule ServidorHackathon do
  @moduledoc """
  Servidor central de la Hackathon Code4Future.
  Maneja todas las peticiones de los clientes conectados.
  """

  alias Adaptadores.Almacenamiento
  alias Servicios.{ServicioParticipantes, ServicioEquipos, ServicioProyectos, ServicioMentoria}

  @nombre_servicio :hackathon_server

  def main() do

    IO.puts("   SERVIDOR HACKATHON CODE4FUTURE - INICIADO  ")


    Process.register(self(), @nombre_servicio)

    # Inicializar todos los servicios
    IO.puts("  Iniciando servicios...")
    {:ok, _} = Almacenamiento.iniciar()
    IO.puts("    Almacenamiento")

    {:ok, _} = ServicioParticipantes.iniciar()
    IO.puts("    Servicio de Participantes")

    {:ok, _} = ServicioEquipos.iniciar()
    IO.puts("    Servicio de Equipos")

    {:ok, _} = ServicioProyectos.iniciar()
    IO.puts("    Servicio de Proyectos")

    {:ok, _} = ServicioMentoria.iniciar()
    IO.puts("    Servicio de Mentoría")

    cargar_datos_ejemplo()

    IO.puts("\n Todos los servicios activos")
    IO.puts(" Esperando conexiones de clientes...")
    IO.puts(" Nodo: #{Node.self()}\n")

    bucle_servidor(%{clientes_chat: %{}})
  end

  defp cargar_datos_ejemplo() do
    IO.puts("\n Cargando datos de ejemplo...")

    # Crear participantes
    ServicioParticipantes.solicitar_registrar("Juan Pérez", "juan@hackathon.com", :participante)
    ServicioParticipantes.solicitar_registrar("María García", "maria@hackathon.com", :participante)
    ServicioParticipantes.solicitar_registrar("Pedro López", "pedro@hackathon.com", :participante)

    # Crear equipos (SIN proyectos automáticos)
    ServicioEquipos.solicitar_crear("Innovadores", "Educacion", "Juan Pérez")
    ServicioEquipos.solicitar_crear("EcoTech", "Ambiental", "María García")

    # Crear mentores
    ServicioMentoria.solicitar_registrar("Dr. Carlos Ruiz", "carlos@hackathon.com", "Inteligencia Artificial")
    ServicioMentoria.solicitar_registrar("Ing. Ana López", "ana@hackathon.com", "Desarrollo Web")

    IO.puts(" Datos de ejemplo cargados")
  end

  defp bucle_servidor(estado) do
    receive do

      {pid_cliente, :registrar_participante, nombre, correo, rol} ->
        log_peticion(pid_cliente, "Registrar participante: #{nombre}")
        resultado = ServicioParticipantes.solicitar_registrar(nombre, correo, rol)
        send(pid_cliente, {:respuesta_registro, resultado})
        bucle_servidor(estado)

      {pid_cliente, :listar_participantes} ->
        log_peticion(pid_cliente, "Listar participantes")
        participantes = ServicioParticipantes.solicitar_listar()
        send(pid_cliente, {:lista_participantes, participantes})
        bucle_servidor(estado)

      {pid_cliente, :listar_equipos} ->
        log_peticion(pid_cliente, "Listar equipos")
        equipos = ServicioEquipos.solicitar_listar()
        send(pid_cliente, {:lista_equipos, equipos})
        bucle_servidor(estado)

      {pid_cliente, :crear_equipo, nombre, tema, lider} ->
        log_peticion(pid_cliente, "Crear equipo: #{nombre}")
        resultado = ServicioEquipos.solicitar_crear(nombre, tema, lider)
        send(pid_cliente, {:equipo_creado, resultado})
        bucle_servidor(estado)

      {pid_cliente, :unirse_equipo, nombre_equipo, nombre_miembro} ->
        log_peticion(pid_cliente, "Unirse a equipo: #{nombre_equipo}")
        resultado = ServicioEquipos.solicitar_agregar_miembro(nombre_equipo, nombre_miembro)
        send(pid_cliente, {:resultado_unirse, resultado})
        bucle_servidor(estado)

      {pid_cliente, :obtener_equipo, nombre_equipo} ->
        log_peticion(pid_cliente, "Obtener info equipo: #{nombre_equipo}")
        equipo = ServicioEquipos.solicitar_obtener(nombre_equipo)
        send(pid_cliente, {:info_equipo, equipo})
        bucle_servidor(estado)

      {pid_cliente, :activar_equipo, nombre_equipo} ->
        log_peticion(pid_cliente, "Activar equipo: #{nombre_equipo}")
        resultado = ServicioEquipos.solicitar_cambiar_estado(nombre_equipo, :activo)
        send(pid_cliente, {:resultado_activar, resultado})
        bucle_servidor(estado)

      {pid_cliente, :desactivar_equipo, nombre_equipo} ->
        log_peticion(pid_cliente, "Desactivar equipo: #{nombre_equipo}")
        resultado = ServicioEquipos.solicitar_cambiar_estado(nombre_equipo, :inactivo)
        send(pid_cliente, {:resultado_desactivar, resultado})
        bucle_servidor(estado)

      # ========== GESTIÓN DE PROYECTOS ==========
      {pid_cliente, :crear_proyecto, nombre_equipo, titulo, descripcion, categoria} ->
        log_peticion(pid_cliente, "Crear proyecto para: #{nombre_equipo}")
        resultado = ServicioProyectos.solicitar_crear(nombre_equipo, titulo, descripcion, categoria)
        send(pid_cliente, {:proyecto_creado, resultado})
        bucle_servidor(estado)

      {pid_cliente, :obtener_proyecto, nombre_equipo} ->
        log_peticion(pid_cliente, "Obtener proyecto: #{nombre_equipo}")
        proyecto = ServicioProyectos.solicitar_obtener(nombre_equipo)
        send(pid_cliente, {:info_proyecto, proyecto})
        bucle_servidor(estado)

      {pid_cliente, :listar_proyectos} ->
        log_peticion(pid_cliente, "Listar todos los proyectos")
        proyectos = ServicioProyectos.solicitar_listar()
        send(pid_cliente, {:lista_proyectos, proyectos})
        bucle_servidor(estado)

      {pid_cliente, :listar_proyectos_activos} ->
        log_peticion(pid_cliente, "Listar proyectos activos")
        proyectos = ServicioProyectos.solicitar_listar_por_estado(:activo)
        send(pid_cliente, {:lista_proyectos, proyectos})
        bucle_servidor(estado)

      {pid_cliente, :listar_proyectos_inactivos} ->
        log_peticion(pid_cliente, "Listar proyectos inactivos")
        proyectos = ServicioProyectos.solicitar_listar_por_estado(:inactivo)
        send(pid_cliente, {:lista_proyectos, proyectos})
        bucle_servidor(estado)

      {pid_cliente, :listar_proyectos_categoria, categoria} ->
        log_peticion(pid_cliente, "Listar proyectos categoría: #{categoria}")
        proyectos = ServicioProyectos.solicitar_listar_por_categoria(categoria)
        send(pid_cliente, {:lista_proyectos, proyectos})
        bucle_servidor(estado)

      {pid_cliente, :agregar_avance, nombre_equipo, texto_avance} ->
        log_peticion(pid_cliente, "Agregar avance a: #{nombre_equipo}")
        resultado = ServicioProyectos.solicitar_agregar_avance(nombre_equipo, texto_avance)
        send(pid_cliente, {:avance_agregado, resultado})

        # Notificar a todos los clientes monitoreando este proyecto
        notificar_avance_a_monitores(estado, nombre_equipo, texto_avance)
        bucle_servidor(estado)

      {pid_cliente, :actualizar_proyecto, nombre_equipo, titulo, descripcion} ->
        log_peticion(pid_cliente, "Actualizar proyecto: #{nombre_equipo}")
        resultado = ServicioProyectos.solicitar_actualizar_detalles(nombre_equipo, titulo, descripcion)
        send(pid_cliente, {:proyecto_actualizado, resultado})
        bucle_servidor(estado)

      {pid_cliente, :monitorear_proyecto, nombre_equipo} ->
        log_peticion(pid_cliente, "Monitorear proyecto: #{nombre_equipo}")
        resultado = ServicioProyectos.solicitar_suscribir(nombre_equipo, pid_cliente)
        send(pid_cliente, {:suscripcion_confirmada, resultado})
        bucle_servidor(estado)

      # ========== GESTIÓN DE MENTORES ==========
      {pid_cliente, :registrar_mentor, nombre, correo, especialidad} ->
        log_peticion(pid_cliente, "Registrar mentor: #{nombre}")
        resultado = ServicioMentoria.solicitar_registrar(nombre, correo, especialidad)
        send(pid_cliente, {:mentor_registrado, resultado})
        bucle_servidor(estado)

      {pid_cliente, :listar_mentores} ->
        log_peticion(pid_cliente, "Listar mentores")
        mentores = ServicioMentoria.solicitar_listar()
        send(pid_cliente, {:lista_mentores, mentores})
        bucle_servidor(estado)

      # ========== SISTEMA DE CHAT ==========
      {pid_cliente, :unirse_chat, canal, nombre_usuario} ->
        log_peticion(pid_cliente, "Unirse a chat: #{canal}")
        nuevo_estado = registrar_cliente_chat(estado, canal, pid_cliente, nombre_usuario)
        send(pid_cliente, {:chat_conectado, :ok})

        # LOG en servidor
        IO.puts(IO.ANSI.green() <> "[CHAT]  #{nombre_usuario} se unió al canal '#{canal}'" <> IO.ANSI.reset())

        # Notificar a otros en el canal
        broadcast_chat(nuevo_estado, canal, "Sistema", " #{nombre_usuario} se ha unido al chat", pid_cliente)
        bucle_servidor(nuevo_estado)

      {pid_cliente, :enviar_mensaje_chat, canal, autor, texto} ->
        # LOG en servidor
        timestamp = obtener_timestamp()
        IO.puts(IO.ANSI.cyan() <> "[#{timestamp}][CHAT:#{canal}] #{autor}: #{texto}" <> IO.ANSI.reset())

        # Broadcast a TODOS excepto al que envió el mensaje
        broadcast_chat(estado, canal, autor, texto, pid_cliente)
        bucle_servidor(estado)

      {pid_cliente, :salir_chat, canal, nombre_usuario} ->
        log_peticion(pid_cliente, "Salir de chat: #{canal}")
        nuevo_estado = desregistrar_cliente_chat(estado, canal, pid_cliente)

        # LOG en servidor
        IO.puts(IO.ANSI.yellow() <> "[CHAT]  #{nombre_usuario} salió del canal '#{canal}'" <> IO.ANSI.reset())

        broadcast_chat(nuevo_estado, canal, "Sistema", " #{nombre_usuario} ha salido del chat", pid_cliente)
        send(pid_cliente, {:chat_desconectado, :ok})
        bucle_servidor(nuevo_estado)

      # ========== MENSAJE DESCONOCIDO ==========
      mensaje ->
        IO.puts("  Mensaje no reconocido: #{inspect(mensaje)}")
        bucle_servidor(estado)
    end
  end

  # ========== FUNCIONES AUXILIARES ==========

  defp log_peticion(pid_cliente, accion) do
    timestamp = obtener_timestamp()
    IO.puts("[#{timestamp}]  Cliente #{inspect(pid_cliente)}: #{accion}")
  end

  defp obtener_timestamp() do
    {{_year, _month, _day}, {hour, minute, second}} = :calendar.local_time()
    :io_lib.format("~2..0B:~2..0B:~2..0B", [hour, minute, second])
    |> IO.iodata_to_binary()
  end

  defp registrar_cliente_chat(estado, canal, pid_cliente, nombre_usuario) do
    clientes_canal = Map.get(estado.clientes_chat, canal, [])
    nuevos_clientes = [{pid_cliente, nombre_usuario} | clientes_canal]
    nuevos_clientes_chat = Map.put(estado.clientes_chat, canal, nuevos_clientes)
    %{estado | clientes_chat: nuevos_clientes_chat}
  end

  defp desregistrar_cliente_chat(estado, canal, pid_cliente) do
    clientes_canal = Map.get(estado.clientes_chat, canal, [])
    nuevos_clientes = Enum.reject(clientes_canal, fn {pid, _nombre} -> pid == pid_cliente end)
    nuevos_clientes_chat = Map.put(estado.clientes_chat, canal, nuevos_clientes)
    %{estado | clientes_chat: nuevos_clientes_chat}
  end

  defp broadcast_chat(estado, canal, autor, texto, remitente_pid) do
    timestamp = obtener_timestamp()
    clientes_canal = Map.get(estado.clientes_chat, canal, [])

    # Enviar mensajes a todos los clientes (incluso remotos)
    Enum.each(clientes_canal, fn {pid, _nombre} ->
      # No enviar al remitente
      if pid != remitente_pid do
        # Usar try/catch para manejar PIDs remotos o muertos
        try do
          send(pid, {:mensaje_chat, autor, texto, timestamp})
        catch
          :error, _ -> :ok
        end
      end
    end)

    estado
  end

  defp notificar_avance_a_monitores(_estado, _nombre_equipo, _texto_avance) do
    # Placeholder para futuras notificaciones
    :ok
  end
end

# Iniciar el servidor
ServidorHackathon.main()
