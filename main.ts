import engine, { System } from "engine"
import { newAnimation } from "plugins/image"
// import "./plugins/effects"

// import solarsystem from require("solarsystem")

engine.load = () => {
    // solarsystem.load()

    newAnimation({name:"person_stand", frames:[1], rows:1, cols:3})
    newAnimation({name:"person_walk", frames:[2,3], rows:1, cols:3, speed:10})
}

System("image", "morph")
    .update((ent) => {
        if (love.mouse.getX() > love.graphics.getWidth() / 2)
            ent.image.name = "father.png"
        else 
            ent.image.name = "son.png"
    })