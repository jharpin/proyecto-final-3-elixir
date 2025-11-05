# verificar_estructura.exs
# Script para verificar que todos los archivos existen

IO.puts("Verificando estructura del proyecto...\n")

archivos_necesarios = [
  "domain/participante.ex",
  "domain/equipo.ex",
  "domain/proyecto.ex",
  "domain/mentor.ex",
  "adapters/almacenamiento.ex",
  "adapters/procesador_comandos.ex",
  "servicios/servicio_participantes.ex",
  "servicios/servicio_equipos.ex",
  "servicios/servicio_proyectos.ex",
  "servicios/servicio_mentoria.ex",
  "servicios/servicio_chat.ex"
]

Enum.each(archivos_necesarios, fn archivo ->
  if File.exists?(archivo) do
    IO.puts("✓ #{archivo}")
  else
    IO.puts("✗ #{archivo} - NO ENCONTRADO")
  end
end)

IO.puts("\nDirectorio actual: #{File.cwd!()}")
