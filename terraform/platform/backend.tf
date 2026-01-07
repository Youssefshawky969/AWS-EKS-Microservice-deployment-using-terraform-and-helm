terraform { 
  cloud { 
    
    organization = "youssef_eks" 

    workspaces { 
      name = "eks" 
    } 
  } 
}