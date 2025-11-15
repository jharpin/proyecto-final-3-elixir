# principal.exs
# Archivo principal de la aplicación Hackathon Code4Future

# Compilar todos los módulos del dominio
Code.require_file("domain/participante.ex", __DIR__)
Code.require_file("domain/equipo.ex", __DIR__)
Code.require_file("domain/proyecto.ex", __DIR__)
Code.require_file("domain/mentor.ex", __DIR__)

# Compilar adaptadores
Code.require_file("adapters/almacenamiento.ex", __DIR__)
Code.require_file("adapters/procesador_comandos.ex", __DIR__)

# Compilar servicios
Code.require_file("servicios/servicio_participantes.ex", __DIR__)
Code.require_file("servicios/servicio_equipos.ex", __DIR__)
Code.require_file("servicios/servicio_proyectos.ex", __DIR__)
Code.require_file("servicios/servicio_mentoria.ex", __DIR__)
Code.require_file("servicios/servicio_chat.ex", __DIR__)

defmodule AplicacionHackathon do
  @moduledoc """
  Aplicación principal para la Hackathon Code4Future.
  Gestiona equipos, proyectos, comunicación y mentoría.
  """

  alias Servicios.{ServicioParticipantes, ServicioEquipos, ServicioProyectos}
  alias Servicios.{ServicioMentoria, ServicioChat}
  alias Adaptadores.{ProcesadorComandos, Almacenamiento}

  def iniciar() do
    mostrar_banner()
    inicializar_servicios()
    cargar_datos_ejemplo()

    IO.puts("\n Sistema iniciado correctamente")
    IO.puts("Escribe /ayuda para ver los comandos disponibles\n")

    ciclo_principal()
  end

  # Muestra el banner de bienvenida
  defp mostrar_banner() do
    IO.puts("""
    Hacketon CODE4FUTURE
    Proyecto Final - Programación 3

    """)
  end

  # Inicializa todos los servicios del sistema
  defp inicializar_servicios() do
    IO.puts(" Iniciando servicios...")

    {:ok, _} = Almacenamiento.iniciar()
    IO.puts("   Almacenamiento")

    {:ok, _} = ServicioParticipantes.iniciar()
    IO.puts("   Servicio de Participantes")

    {:ok, _} = ServicioEquipos.iniciar()
    IO.puts("   Servicio de Equipos")

    {:ok, _} = ServicioProyectos.iniciar()
    IO.puts("   Servicio de Proyectos")

    {:ok, _} = ServicioMentoria.iniciar()
    IO.puts("   Servicio de Mentoría")

    {:ok, _} = ServicioChat.iniciar()
    IO.puts("   Servicio de Chat")
  end

  # Carga datos de ejemplo para demostración
  defp cargar_datos_ejemplo() do
    IO.puts("\n Cargando datos de ejemplo...")

    # Crear participantes
    ServicioParticipantes.solicitar_registrar("Juan Pérez", "juan@hackathon.com", :participante)
    ServicioParticipantes.solicitar_registrar("María García", "maria@hackathon.com", :participante)
    ServicioParticipantes.solicitar_registrar("Pedro López", "pedro@hackathon.com", :participante)

    # Crear equipos
    ServicioEquipos.solicitar_crear("Innovadores", "Educación", "Juan Pérez")
    ServicioEquipos.solicitar_crear("EcoTech", "Ambiental", "María García")
    ServicioEquipos.solicitar_crear("SocialApp", "Social", "Pedro López")

    # Crear mentores
    ServicioMentoria.solicitar_registrar("Dr. Carlos Ruiz", "carlos@hackathon.com", "Inteligencia Artificial")
    ServicioMentoria.solicitar_registrar("Ing. Ana López", "ana@hackathon.com", "Desarrollo Web")

    IO.puts(" Datos de ejemplo cargados\n")
  end

  # Ciclo principal que procesa comandos del usuario
  defp ciclo_principal() do
    entrada = IO.gets("hackathon> ") |> String.trim()

    case ProcesadorComandos.parsear(entrada) do
      {:salir, _} ->
        IO.puts("\n Gracias por usar el sistema.\n")
        :ok

      {:ayuda, _} ->
        IO.puts(ProcesadorComandos.mostrar_ayuda())
        ciclo_principal()

      {:registrar, _} ->
        manejar_registro()
        ciclo_principal()

      {:listar_participantes, _} ->
        manejar_listar_participantes()
        ciclo_principal()

      {:listar_equipos, _} ->
        manejar_listar_equipos()
        ciclo_principal()

      {:crear_equipo, datos} ->
        manejar_crear_equipo(datos)
        ciclo_principal()

      {:unirse_equipo, nombre_equipo} ->
        manejar_unirse_equipo(nombre_equipo)
        ciclo_principal()

      {:ver_proyecto, nombre_equipo} ->
        manejar_ver_proyecto(nombre_equipo)
        ciclo_principal()

      {:agregar_avance, nombre_equipo} ->
        manejar_agregar_avance(nombre_equipo)
        ciclo_principal()

      {:abrir_chat, nombre_equipo} ->
        manejar_chat(nombre_equipo)
        ciclo_principal()

      {:listar_mentores, _} ->
        manejar_listar_mentores()
        ciclo_principal()

      {:salir_equipo, _} ->
        manejar_salir_equipo()
        ciclo_principal()

      {:desconocido, _} ->
        IO.puts(" Comando no reconocido. Usa /ayuda para ver los comandos disponibles.")
        ciclo_principal()

      {:error, msg} ->
        IO.puts(" Error: #{msg}")
        ciclo_principal()
    end
  end

  # ========== MANEJADORES DE COMANDOS ==========

  defp manejar_registro() do
    IO.puts("\n REGISTRO DE PARTICIPANTE")
    IO.puts("--------------------")

    nombre = IO.gets("Nombre completo: ") |> String.trim()
    correo = IO.gets("Correo electrónico: ") |> String.trim()

    IO.puts("\nTipo de participante:")
    IO.puts("1. Participante")
    IO.puts("2. Mentor")
    opcion = IO.gets("Selecciona (1 o 2): ") |> String.trim()

    rol = if opcion == "2", do: :mentor, else: :participante

    case ServicioParticipantes.solicitar_registrar(nombre, correo, rol) do
      {:ok, _participante} ->
        IO.puts("\n Registro exitoso, Bienvenido #{nombre}\n")

      {:error, msg} ->
        IO.puts("\n Error: #{msg}\n")
    end
  end

  defp manejar_listar_participantes() do
    participantes = ServicioParticipantes.solicitar_listar()

    if Enum.empty?(participantes) do
      IO.puts("\n No hay participantes registrados.\n")
    else
      IO.puts("\n PARTICIPANTES REGISTRADOS\n -------")

      Enum.each(participantes, fn p ->
        equipo = if p.equipo, do: p.equipo, else: "Sin equipo"
        IO.puts("• #{p.nombre} (#{p.correo})")
        IO.puts("  Rol: #{p.rol} | Equipo: #{equipo}")
        IO.puts(" -------")
      end)

      IO.puts("")
    end
  end

  defp manejar_listar_equipos() do
    equipos = ServicioEquipos.solicitar_listar()

    if Enum.empty?(equipos) do
      IO.puts("\n No hay equipos registrados.\n")
    else
      IO.puts("\n EQUIPOS ACTIVOS")
      IO.puts("--------")

      Enum.each(equipos, fn equipo ->
        IO.puts("• #{equipo.nombre}")
        IO.puts("  Tema: #{equipo.tema}")
        IO.puts("  Líder: #{equipo.lider}")
        IO.puts("  Miembros: #{length(equipo.miembros)}")
        IO.puts("  ---------")
      end)

      IO.puts("")
    end
  end

  defp manejar_crear_equipo(%{nombre: nombre, tema: tema}) do
    lider = IO.gets("\nIngresa tu nombre (líder del equipo): ") |> String.trim()

    case ServicioEquipos.solicitar_crear(nombre, tema, lider) do
      {:ok, _equipo} ->
        IO.puts("\n Equipo '#{nombre}' creado exitosamente!")
        IO.puts("   Tema: #{tema}\n")

      {:error, msg} ->
        IO.puts("\n Error: #{msg}\n")
    end
  end

  defp manejar_unirse_equipo(nombre_equipo) do
    correo = IO.gets("\nIngresa tu correo electrónico: ") |> String.trim()

    # Obtener el participante por correo
    participante = ServicioParticipantes.solicitar_obtener(correo)

    if participante == nil do
      IO.puts("\n Error: No se encontró un participante con ese correo. Debes registrarte primero.\n")
    else
      case ServicioEquipos.solicitar_agregar_miembro(nombre_equipo, participante.nombre) do
        {:ok, msg} ->
          IO.puts("\n #{msg}\n")

        {:error, msg} ->
          IO.puts("\n Error: #{msg}\n")
      end
    end
  end

  defp manejar_ver_proyecto(nombre_equipo) do
    case ServicioProyectos.solicitar_obtener(nombre_equipo) do
      nil ->
        IO.puts("\n No existe un proyecto para el equipo '#{nombre_equipo}'\n")

      proyecto ->
        IO.puts("\n PROYECTO: #{proyecto.titulo}")
        IO.puts("---------")
        IO.puts("Equipo: #{proyecto.nombre_equipo}")
        IO.puts("Categoría: #{proyecto.categoria}")
        IO.puts("Estado: #{proyecto.estado}")
        IO.puts("\nDescripción:")
        IO.puts("#{proyecto.descripcion}")

        if length(proyecto.avances) > 0 do
          IO.puts("\n Avances (#{length(proyecto.avances)}):")
          Enum.each(proyecto.avances, fn avance ->
            IO.puts("  • #{avance.texto}")
          end)
        end

        if length(proyecto.retroalimentacion) > 0 do
          IO.puts("\n Retroalimentación:")
          Enum.each(proyecto.retroalimentacion, fn retro ->
            IO.puts("  [#{retro.mentor}]: #{retro.comentario}")
          end)
        end

        IO.puts("")
    end
  end

  defp manejar_agregar_avance(nombre_equipo) do
    IO.puts("\n AGREGAR AVANCE")
    avance = IO.gets("Describe el avance: ") |> String.trim()

    case ServicioProyectos.solicitar_agregar_avance(nombre_equipo, avance) do
      {:ok, msg} ->
        IO.puts("\n #{msg}\n")

      {:error, msg} ->
        IO.puts("\n Error: #{msg}\n")
    end
  end

  defp manejar_chat(canal) do
    IO.puts("\n CHAT: #{canal}")
    IO.puts("----------")
    IO.puts("(Escribe 'salir' para volver al menú)\n")

    # Mostrar mensajes anteriores
    mensajes = ServicioChat.solicitar_obtener_mensajes(canal)
    if length(mensajes) > 0 do
      IO.puts(" Mensajes anteriores:")
      Enum.each(mensajes, fn msg ->
        timestamp = Calendar.strftime(msg.timestamp, "%H:%M")
        IO.puts("  [#{timestamp}] #{msg.autor}: #{msg.texto}")
      end)
      IO.puts("")
    end

    ciclo_chat(canal)
  end

  defp ciclo_chat(canal) do
    entrada = IO.gets("#{canal}> ") |> String.trim()

    if entrada == "salir" do
      IO.puts("Saliendo del chat...\n")
      :ok
    else
      # Por simplicidad, usamos un nombre fijo
      # En una versión completa usaríamos el usuario logueado
      ServicioChat.solicitar_enviar_mensaje(canal, "Usuario", entrada)
      ciclo_chat(canal)
    end
  end

  defp manejar_listar_mentores() do
    mentores = ServicioMentoria.solicitar_listar()

    if Enum.empty?(mentores) do
      IO.puts("\n No hay mentores registrados.\n")
    else
      IO.puts("\n MENTORES DISPONIBLES")
      IO.puts("------------------")

      Enum.each(mentores, fn mentor ->
        disponible = if mentor.disponible, do: "✓", else: "✗"
        IO.puts("#{disponible} #{mentor.nombre}")
        IO.puts("  Especialidad: #{mentor.especialidad}")
        IO.puts("  Equipos asignados: #{length(mentor.equipos_asignados)}")
        IO.puts(" ------------------")
      end)

      IO.puts("")
    end
  end

  defp manejar_salir_equipo() do
    IO.puts("\n SALIR DEL EQUIPO")
    IO.puts("--------------------")

    correo = IO.gets("Ingresa tu correo electrónico: ") |> String.trim()

    # Obtener el participante
    participante = ServicioParticipantes.solicitar_obtener(correo)

    if participante == nil do
      IO.puts("\n Error: No se encontró un participante con ese correo.\n")
    else
      if participante.equipo == nil do
        IO.puts("\n No perteneces a ningún equipo.\n")
      else
        # Confirmar
        IO.puts("\nEstás a punto de salir del equipo: #{participante.equipo}")
        confirmacion = IO.gets("¿Estás seguro? (si/no): ") |> String.trim() |> String.downcase()

        if confirmacion == "si" or confirmacion == "s" do
          # Remover del equipo
          nombre_equipo = participante.equipo

          case ServicioEquipos.solicitar_obtener(nombre_equipo) do
            nil ->
              IO.puts("\n Error: El equipo no existe.\n")

            equipo ->
              # Remover al miembro del equipo (esto también desasigna el equipo del participante)
              case Dominio.Equipo.remover_miembro(equipo, participante.nombre) do
                {:ok, equipo_actualizado} ->
                  # Guardar equipo actualizado
                  Almacenamiento.guardar_equipo(equipo_actualizado)

                  # Desasignar equipo del participante
                  case ServicioParticipantes.solicitar_desasignar_equipo(correo) do
                    {:ok, msg} ->
                      IO.puts("\n #{msg}\n")
                    {:error, msg} ->
                      IO.puts("\n Error: #{msg}\n")
                  end

                {:error, msg} ->
                  IO.puts("\n Error: #{msg}\n")
              end
          end
        else
          IO.puts("\n Operación cancelada.\n")
        end
      end
    end
  end
end

# Iniciar la aplicación
AplicacionHackathon.iniciar()
