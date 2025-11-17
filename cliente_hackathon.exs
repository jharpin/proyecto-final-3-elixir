# cliente_hackathon.exs
# CLIENTE DE LA HACKATHON CODE4FUTURE

# Cargar el procesador de comandos
Code.require_file("adapters/procesador_comandos.ex", __DIR__)

defmodule ClienteHackathon do
  @moduledoc """
  Cliente para conectarse al servidor de la Hackathon.
  Permite ejecutar todos los comandos de forma remota.
  """

  alias Adaptadores.ProcesadorComandos

  # CONFIGURACIÓN - Modificar con la IP del servidor
  @servidor_nodo :"servidor@192.168.1.56"
  @servidor_remoto {:hackathon_server, @servidor_nodo}

  def main() do
    mostrar_banner()
    conectar_servidor()
  end

  defp mostrar_banner() do
    IO.puts("\n╔════════════════════════════════════════════════════╗")
    IO.puts("║     CLIENTE HACKATHON CODE4FUTURE                  ║")
    IO.puts("╚════════════════════════════════════════════════════╝\n")
  end

  defp conectar_servidor() do
    IO.puts("🔌 Conectando al servidor: #{@servidor_nodo}")

    case Node.connect(@servidor_nodo) do
      true ->
        IO.puts("✅ Conectado exitosamente al servidor")
        IO.puts("📝 Escribe /ayuda para ver los comandos disponibles\n")
        ciclo_principal()

      false ->
        IO.puts("❌ No se pudo conectar al servidor")
        IO.puts("Verifica que:")
        IO.puts("  1. El servidor esté ejecutándose")
        IO.puts("  2. La IP sea correcta: #{@servidor_nodo}")
        IO.puts("  3. La cookie sea la misma: hackathon_secret\n")

      :ignored ->
        IO.puts("⚠️  Ya estabas conectado al servidor")
        ciclo_principal()
    end
  end

  defp ciclo_principal() do
    entrada = IO.gets("hackathon> ") |> String.trim()

    case ProcesadorComandos.parsear(entrada) do
      {:salir, _} ->
        IO.puts("\n👋 Gracias por usar el sistema. ¡Hasta pronto!\n")
        :ok

      {:ayuda, _} ->
        IO.puts(ProcesadorComandos.mostrar_ayuda())
        ciclo_principal()

      {:registrar, _} ->
        manejar_registro_remoto()
        ciclo_principal()

      {:listar_participantes, _} ->
        manejar_listar_participantes_remoto()
        ciclo_principal()

      {:listar_equipos, _} ->
        manejar_listar_equipos_remoto()
        ciclo_principal()

      {:crear_equipo, datos} ->
        manejar_crear_equipo_remoto(datos)
        ciclo_principal()

      {:unirse_equipo, nombre_equipo} ->
        manejar_unirse_equipo_remoto(nombre_equipo)
        ciclo_principal()

      {:ver_proyecto, nombre_equipo} ->
        manejar_ver_proyecto_remoto(nombre_equipo)
        ciclo_principal()

      {:agregar_avance, nombre_equipo} ->
        manejar_agregar_avance_remoto(nombre_equipo)
        ciclo_principal()

      {:abrir_chat, canal} ->
        manejar_chat_remoto(canal)
        ciclo_principal()

      {:listar_mentores, _} ->
        manejar_listar_mentores_remoto()
        ciclo_principal()

      {:activar_equipo, nombre_equipo} ->
        manejar_activar_equipo_remoto(nombre_equipo)
        ciclo_principal()

      {:desactivar_equipo, nombre_equipo} ->
        manejar_desactivar_equipo_remoto(nombre_equipo)
        ciclo_principal()

      {:listar_proyectos, _} ->
        manejar_listar_proyectos_remoto()
        ciclo_principal()

      {:listar_proyectos_activos, _} ->
        manejar_listar_proyectos_activos_remoto()
        ciclo_principal()

      {:listar_proyectos_inactivos, _} ->
        manejar_listar_proyectos_inactivos_remoto()
        ciclo_principal()

      {:listar_proyectos_categoria, categoria} ->
        manejar_listar_proyectos_categoria_remoto(categoria)
        ciclo_principal()

      {:actualizar_proyecto, nombre_equipo} ->
        manejar_actualizar_proyecto_remoto(nombre_equipo)
        ciclo_principal()

      {:monitorear_proyecto, nombre_equipo} ->
        manejar_monitorear_proyecto_remoto(nombre_equipo)
        ciclo_principal()

      {:desconocido, _} ->
        IO.puts("❌ Comando no reconocido. Usa /ayuda para ver los comandos disponibles.")
        ciclo_principal()

      {:error, msg} ->
        IO.puts("❌ Error: #{msg}")
        ciclo_principal()
    end
  end

  # ========== MANEJADORES DE COMANDOS REMOTOS ==========

  defp manejar_registro_remoto() do
    IO.puts("\n╔════════════════════════════════════════╗")
    IO.puts("║   REGISTRO DE PARTICIPANTE/MENTOR      ║")
    IO.puts("╚════════════════════════════════════════╝")

    nombre = IO.gets("\nNombre completo: ") |> String.trim()
    correo = IO.gets("Correo electrónico: ") |> String.trim()

    IO.puts("\nTipo de registro:")
    IO.puts("1. Participante")
    IO.puts("2. Mentor")
    opcion = IO.gets("Selecciona (1 o 2): ") |> String.trim()

    if opcion == "2" do
      # Registrar mentor
      especialidad = IO.gets("Especialidad: ") |> String.trim()
      send(@servidor_remoto, {self(), :registrar_mentor, nombre, correo, especialidad})

      receive do
        {:mentor_registrado, {:ok, _mentor}} ->
          IO.puts("\n✅ Mentor registrado exitosamente. ¡Bienvenido #{nombre}!\n")

        {:mentor_registrado, {:error, msg}} ->
          IO.puts("\n❌ Error: #{msg}\n")
      after
        5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
      end
    else
      # Registrar participante
      rol = :participante
      send(@servidor_remoto, {self(), :registrar_participante, nombre, correo, rol})

      receive do
        {:respuesta_registro, {:ok, _participante}} ->
          IO.puts("\n✅ Registro exitoso. ¡Bienvenido #{nombre}!\n")

        {:respuesta_registro, {:error, msg}} ->
          IO.puts("\n❌ Error: #{msg}\n")
      after
        5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
      end
    end
  end

  defp manejar_listar_participantes_remoto() do
    send(@servidor_remoto, {self(), :listar_participantes})

    receive do
      {:lista_participantes, participantes} ->
        if Enum.empty?(participantes) do
          IO.puts("\n📭 No hay participantes registrados.\n")
        else
          IO.puts("\n╔════════════════════════════════════════╗")
          IO.puts("║     PARTICIPANTES REGISTRADOS          ║")
          IO.puts("╚════════════════════════════════════════╝\n")

          Enum.each(participantes, fn p ->
            equipo = if p.equipo, do: p.equipo, else: "Sin equipo"
            IO.puts("👤 #{p.nombre}")
            IO.puts("   📧 #{p.correo}")
            IO.puts("   👥 Equipo: #{equipo}")
            IO.puts("   " <> String.duplicate("─", 40))
          end)

          IO.puts("")
        end
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_listar_equipos_remoto() do
    send(@servidor_remoto, {self(), :listar_equipos})

    receive do
      {:lista_equipos, equipos} ->
        if Enum.empty?(equipos) do
          IO.puts("\n📭 No hay equipos registrados.\n")
        else
          IO.puts("\n╔════════════════════════════════════════╗")
          IO.puts("║          EQUIPOS REGISTRADOS           ║")
          IO.puts("╚════════════════════════════════════════╝\n")

          Enum.each(equipos, fn equipo ->
            estado_icono = if equipo.estado == :activo, do: "✅", else: "⏸️"
            IO.puts("#{estado_icono} #{equipo.nombre}")
            IO.puts("   🎯 Tema: #{equipo.tema}")
            IO.puts("   👑 Líder: #{equipo.lider}")
            IO.puts("   👥 Miembros (#{length(equipo.miembros)}):")

            Enum.each(equipo.miembros, fn miembro ->
              IO.puts("      • #{miembro}")
            end)

            IO.puts("   " <> String.duplicate("─", 40))
          end)

          IO.puts("")
        end
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_crear_equipo_remoto(%{nombre: nombre, tema: tema}) do
    lider = IO.gets("\n👑 Ingresa tu nombre (líder del equipo): ") |> String.trim()

    send(@servidor_remoto, {self(), :crear_equipo, nombre, tema, lider})

    receive do
      {:equipo_creado, {:ok, _equipo}} ->
        IO.puts("\n✅ Equipo '#{nombre}' creado exitosamente!")
        IO.puts("   🎯 Tema: #{tema}")
        IO.puts("   👑 Líder: #{lider}\n")

      {:equipo_creado, {:error, msg}} ->
        IO.puts("\n❌ Error: #{msg}\n")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_unirse_equipo_remoto(nombre_equipo) do
    nombre = IO.gets("\n👤 Ingresa tu nombre: ") |> String.trim()

    send(@servidor_remoto, {self(), :unirse_equipo, nombre_equipo, nombre})

    receive do
      {:resultado_unirse, {:ok, msg}} ->
        IO.puts("\n✅ #{msg}\n")

      {:resultado_unirse, {:error, msg}} ->
        IO.puts("\n❌ Error: #{msg}\n")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_ver_proyecto_remoto(nombre_equipo) do
    send(@servidor_remoto, {self(), :obtener_proyecto, nombre_equipo})

    receive do
      {:info_proyecto, nil} ->
        IO.puts("\n❌ No existe un proyecto para el equipo '#{nombre_equipo}'\n")

      {:info_proyecto, proyecto} ->
        IO.puts("\n╔════════════════════════════════════════╗")
        IO.puts("║          PROYECTO: #{String.pad_trailing(proyecto.titulo, 23)} ║")
        IO.puts("╚════════════════════════════════════════╝")
        IO.puts("\n📌 Equipo: #{proyecto.nombre_equipo}")
        IO.puts("🎯 Categoría: #{proyecto.categoria}")
        IO.puts("📊 Estado: #{proyecto.estado}")
        IO.puts("\n📝 Descripción:")
        IO.puts("   #{proyecto.descripcion}")

        if length(proyecto.avances) > 0 do
          IO.puts("\n🚀 Avances (#{length(proyecto.avances)}):")
          Enum.each(proyecto.avances, fn avance ->
            fecha = Calendar.strftime(avance.fecha, "%Y-%m-%d %H:%M")
            IO.puts("   • [#{fecha}] #{avance.texto}")
          end)
        end

        if length(proyecto.retroalimentacion) > 0 do
          IO.puts("\n💬 Retroalimentación:")
          Enum.each(proyecto.retroalimentacion, fn retro ->
            IO.puts("   [#{retro.mentor}]: #{retro.comentario}")
          end)
        end

        IO.puts("")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_agregar_avance_remoto(nombre_equipo) do
    IO.puts("\n╔════════════════════════════════════════╗")
    IO.puts("║         AGREGAR AVANCE                 ║")
    IO.puts("╚════════════════════════════════════════╝")

    avance = IO.gets("\n📝 Describe el avance: ") |> String.trim()

    send(@servidor_remoto, {self(), :agregar_avance, nombre_equipo, avance})

    receive do
      {:avance_agregado, {:ok, msg}} ->
        IO.puts("\n✅ #{msg}\n")

      {:avance_agregado, {:error, msg}} ->
        IO.puts("\n❌ Error: #{msg}\n")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_chat_remoto(canal) do
    nombre = IO.gets("\n👤 Ingresa tu nombre para el chat: ") |> String.trim()

    send(@servidor_remoto, {self(), :unirse_chat, canal, nombre})

    receive do
      {:chat_conectado, :ok} ->
        IO.puts("\n╔════════════════════════════════════════╗")
        IO.puts("║     💬 CHAT: #{String.pad_trailing(canal, 26)} ║")
        IO.puts("╚════════════════════════════════════════╝")
        IO.puts("Escribe /salir para volver al menú\n")

        # Iniciar ciclo de chat
        ciclo_chat(canal, nombre)

      {:chat_conectado, {:error, msg}} ->
        IO.puts("\n❌ Error: #{msg}\n")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp ciclo_chat(canal, nombre) do
    # Proceso lector (input del usuario)
    pid_lector = spawn(fn -> bucle_lectura_chat(canal, nombre) end)

    # Proceso receptor (mensajes del servidor)
    bucle_receptor_chat(canal, nombre, pid_lector)
  end

  defp bucle_lectura_chat(canal, nombre) do
    entrada = IO.gets("") |> String.trim()

    if entrada == "/salir" do
      send(self(), :salir_chat)
    else
      send(@servidor_remoto, {self(), :enviar_mensaje_chat, canal, nombre, entrada})
      bucle_lectura_chat(canal, nombre)
    end
  end

  defp bucle_receptor_chat(canal, nombre, pid_lector) do
    receive do
      {:mensaje_chat, autor, texto, timestamp} ->
        IO.puts("[#{timestamp}] #{autor}: #{texto}")
        bucle_receptor_chat(canal, nombre, pid_lector)

      :salir_chat ->
        Process.exit(pid_lector, :kill)
        send(@servidor_remoto, {self(), :salir_chat, canal, nombre})

        receive do
          {:chat_desconectado, :ok} ->
            IO.puts("\n👋 Saliste del chat '#{canal}'\n")
        after
          1000 -> IO.puts("\n👋 Saliste del chat '#{canal}'\n")
        end

        :ok
    end
  end

  defp manejar_listar_mentores_remoto() do
    send(@servidor_remoto, {self(), :listar_mentores})

    receive do
      {:lista_mentores, mentores} ->
        if Enum.empty?(mentores) do
          IO.puts("\n📭 No hay mentores registrados.\n")
        else
          IO.puts("\n╔════════════════════════════════════════╗")
          IO.puts("║        MENTORES DISPONIBLES            ║")
          IO.puts("╚════════════════════════════════════════╝\n")

          Enum.each(mentores, fn mentor ->
            disponible = if mentor.disponible, do: "✅ Disponible", else: "⏸️ No disponible"
            IO.puts("👨‍🏫 #{mentor.nombre}")
            IO.puts("   🎓 Especialidad: #{mentor.especialidad}")
            IO.puts("   📧 #{mentor.correo}")
            IO.puts("   #{disponible}")
            IO.puts("   👥 Equipos asignados: #{length(mentor.equipos_asignados)}")
            IO.puts("   " <> String.duplicate("─", 40))
          end)

          IO.puts("")
        end
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_activar_equipo_remoto(nombre_equipo) do
    send(@servidor_remoto, {self(), :activar_equipo, nombre_equipo})

    receive do
      {:resultado_activar, {:ok, msg}} ->
        IO.puts("\n✅ #{msg}\n")

      {:resultado_activar, {:error, msg}} ->
        IO.puts("\n❌ Error: #{msg}\n")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_desactivar_equipo_remoto(nombre_equipo) do
    send(@servidor_remoto, {self(), :desactivar_equipo, nombre_equipo})

    receive do
      {:resultado_desactivar, {:ok, msg}} ->
        IO.puts("\n✅ #{msg}\n")

      {:resultado_desactivar, {:error, msg}} ->
        IO.puts("\n❌ Error: #{msg}\n")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_listar_proyectos_remoto() do
    send(@servidor_remoto, {self(), :listar_proyectos})

    receive do
      {:lista_proyectos, proyectos} ->
        mostrar_lista_proyectos(proyectos, "TODOS LOS PROYECTOS")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_listar_proyectos_activos_remoto() do
    send(@servidor_remoto, {self(), :listar_proyectos_activos})

    receive do
      {:lista_proyectos, proyectos} ->
        mostrar_lista_proyectos(proyectos, "PROYECTOS DE EQUIPOS ACTIVOS")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_listar_proyectos_inactivos_remoto() do
    send(@servidor_remoto, {self(), :listar_proyectos_inactivos})

    receive do
      {:lista_proyectos, proyectos} ->
        mostrar_lista_proyectos(proyectos, "PROYECTOS DE EQUIPOS INACTIVOS")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_listar_proyectos_categoria_remoto(categoria) do
    send(@servidor_remoto, {self(), :listar_proyectos_categoria, categoria})

    receive do
      {:lista_proyectos, proyectos} ->
        mostrar_lista_proyectos(proyectos, "PROYECTOS - CATEGORÍA: #{categoria}")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_actualizar_proyecto_remoto(nombre_equipo) do
    send(@servidor_remoto, {self(), :obtener_proyecto, nombre_equipo})

    receive do
      {:info_proyecto, nil} ->
        IO.puts("\n❌ No existe un proyecto para el equipo '#{nombre_equipo}'\n")

      {:info_proyecto, proyecto} ->
        IO.puts("\n╔════════════════════════════════════════╗")
        IO.puts("║      ACTUALIZAR PROYECTO               ║")
        IO.puts("╚════════════════════════════════════════╝")
        IO.puts("\n📌 Título actual: #{proyecto.titulo}")
        IO.puts("📝 Descripción actual: #{proyecto.descripcion}\n")

        nuevo_titulo = IO.gets("Nuevo título (Enter para mantener): ") |> String.trim()
        nueva_descripcion = IO.gets("Nueva descripción (Enter para mantener): ") |> String.trim()

        titulo_final = if nuevo_titulo == "", do: proyecto.titulo, else: nuevo_titulo
        descripcion_final = if nueva_descripcion == "", do: proyecto.descripcion, else: nueva_descripcion

        send(@servidor_remoto, {self(), :actualizar_proyecto, nombre_equipo, titulo_final, descripcion_final})

        receive do
          {:proyecto_actualizado, {:ok, msg}} ->
            IO.puts("\n✅ #{msg}\n")

          {:proyecto_actualizado, {:error, msg}} ->
            IO.puts("\n❌ Error: #{msg}\n")
        after
          5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
        end
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp manejar_monitorear_proyecto_remoto(nombre_equipo) do
    send(@servidor_remoto, {self(), :monitorear_proyecto, nombre_equipo})

    receive do
      {:suscripcion_confirmada, {:ok, _msg}} ->
        IO.puts("\n╔════════════════════════════════════════╗")
        IO.puts("║    📡 MONITOREANDO PROYECTO            ║")
        IO.puts("╚════════════════════════════════════════╝")
        IO.puts("\n🔔 Recibirás notificaciones en tiempo real")
        IO.puts("⌨️  Presiona Ctrl+C dos veces para detener\n")

        ciclo_monitoreo(nombre_equipo)

      {:suscripcion_confirmada, {:error, msg}} ->
        IO.puts("\n❌ Error: #{msg}\n")
    after
      5000 -> IO.puts("\n❌ Timeout: el servidor no respondió\n")
    end
  end

  defp ciclo_monitoreo(nombre_equipo) do
    receive do
      {:actualizacion_proyecto, :nuevo_avance, ^nombre_equipo, datos} ->
        timestamp = datos.fecha |> Calendar.strftime("%H:%M:%S")
        IO.puts("\n🚀 [#{timestamp}] NUEVO AVANCE DETECTADO!")
        IO.puts("   #{datos.texto}")
        IO.puts("   📊 Total de avances: #{datos.total_avances}\n")
        ciclo_monitoreo(nombre_equipo)

      _ ->
        ciclo_monitoreo(nombre_equipo)
    after
      30000 ->
        IO.puts("⏱️  Sin actividad por 30 segundos. Monitoreo activo...")
        ciclo_monitoreo(nombre_equipo)
    end
  end

  defp mostrar_lista_proyectos(proyectos, titulo) do
    if Enum.empty?(proyectos) do
      IO.puts("\n📭 No hay proyectos para mostrar.\n")
    else
      IO.puts("\n╔════════════════════════════════════════╗")
      IO.puts("║   #{String.pad_trailing(titulo, 38)} ║")
      IO.puts("╚════════════════════════════════════════╝\n")

      Enum.each(proyectos, fn proyecto ->
        estado_icono = if proyecto.estado_equipo == :activo, do: "✅", else: "⏸️"
        IO.puts("#{estado_icono} #{proyecto.titulo}")
        IO.puts("   👥 Equipo: #{proyecto.nombre_equipo}")
        IO.puts("   🎯 Categoría: #{proyecto.categoria}")
        IO.puts("   📊 Estado: #{proyecto.estado}")
        IO.puts("   🚀 Avances: #{length(proyecto.avances)}")
        IO.puts("   " <> String.duplicate("─", 40))
      end)

      IO.puts("")
    end
  end
end

# Iniciar el cliente
ClienteHackathon.main()
