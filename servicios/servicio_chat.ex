defmodule Servicios.ServicioChat do
  @moduledoc """
  Servicio de chat para comunicación en tiempo real.
  Soporta canales por equipo y canal general.
  """

  alias Adaptadores.Almacenamiento

  @nombre_servicio :servicio_chat

  @doc """
  Inicia el servicio de chat
  """
  def iniciar() do
    pid = spawn(fn -> ciclo() end)
    Process.register(pid, @nombre_servicio)
    {:ok, pid}
  end

  @doc """
  Ciclo principal del chat
  """
  defp ciclo() do
    receive do
      {remitente, :enviar_mensaje, canal, autor, texto} ->
        resultado = guardar_mensaje(canal, autor, texto)
        send(remitente, {:mensaje_enviado, resultado})
        ciclo()

      {remitente, :obtener_mensajes, canal} ->
        mensajes = Almacenamiento.obtener_mensajes(canal)
        send(remitente, {:mensajes, mensajes})
        ciclo()

      {remitente, :anuncio_general, texto} ->
        # Mensaje del sistema en canal general
        resultado = guardar_mensaje("general", "Sistema", texto)
        send(remitente, {:anuncio_enviado, resultado})
        ciclo()

      :detener ->
        :ok
    end
  end
#funciones privadas

  defp guardar_mensaje(canal, autor, texto) do
    mensaje = %{
      canal: canal,
      autor: autor,
      texto: texto,
      timestamp: DateTime.utc_now()
    }

    Almacenamiento.guardar_mensaje(mensaje)
    {:ok, "Mensaje enviado"}
  end

  # api

  @doc """
  Solicita enviar un mensaje a un canal
  """
  def solicitar_enviar_mensaje(canal, autor, texto) do
    send(@nombre_servicio, {self(), :enviar_mensaje, canal, autor, texto})

    receive do
      {:mensaje_enviado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end

  @doc """
  Solicita obtener mensajes de un canal
  """
  def solicitar_obtener_mensajes(canal) do
    send(@nombre_servicio, {self(), :obtener_mensajes, canal})

    receive do
      {:mensajes, mensajes} -> mensajes
    after
      5000 -> []
    end
  end

  @doc """
  Envia un anuncio general
  """
  def solicitar_anuncio_general(texto) do
    send(@nombre_servicio, {self(), :anuncio_general, texto})

    receive do
      {:anuncio_enviado, resultado} -> resultado
    after
      5000 -> {:error, "Timeout"}
    end
  end
end
