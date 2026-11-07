# La Vuelta al Plato

Juego de cocina en 2D hecho con **Godot 4**: un viaje de cocina por el mundo. Empezás en **Viandas**, tu local de Buenos Aires: los clientes hacen su pedido y vos cocinás, medís tiempos y temperaturas, salás, cortás, emplatás y servís antes de que se cansen de esperar. Con lo que ganás, abrís locales en otros países, cada uno con su gastronomía y su forma de cocinar (mapamundi del modo historia).

**Jugalo en el navegador:** https://francogaytan.github.io/la-vuelta-al-plato/

## Cómo se juega

1. **Pedidos:** la moza anota el pedido del cliente del mostrador.
2. **Cocina:** arrastrá los ingredientes de la heladera a la olla, la plancha, la freidora o el horno, y sacalos en su punto. Las carnes tienen termómetro.
3. **Tabla:** arrastrá la verdura a la tabla y cortala.
4. **Emplatado:** arrastrá al plato lo de la bandeja y la salsa; los toppings se desparraman manteniendo el bowl sobre la comida.
5. **Entrega:** tocá la campanita para servir.

Teclas: `1`–`5` cambian de estación · `P` / `Esc` pausa · `R` recetario · `M` música · `Espacio` corta.

Con lo que ganás cada día podés comprar mejoras en la tienda.

## Correrlo en tu compu

Abrí el proyecto con [Godot 4.7](https://godotengine.org/) (importar `project.godot`) y apretá F5.

## Estructura

- `data.gd`: ingredientes, recetas, niveles y mejoras (para sumar contenido, se edita acá).
- `main.gd`: lógica del juego y estaciones.
- `art.gd` y `views/`: dibujos hechos por código (personajes, cocina, efectos).
- `assets/`: ilustraciones SVG, música y sonidos.
- `tools/`: generadores de la música, los sonidos y algunas ilustraciones.

Cada vez que se sube un cambio a `main`, GitHub Actions compila la versión web y la publica en GitHub Pages (`.github/workflows/deploy.yml`).
