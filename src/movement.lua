local e = engine 

e.Component("velocity", { x=0, y=0 })

e.System("velocity", "transform")
  :update(function(ent, dt)
    local vel, tf = ent.velocity, ent.transform
    tf.x = tf.x + vel.x * dt 
    tf.y = tf.y + vel.y * dt 
  end)