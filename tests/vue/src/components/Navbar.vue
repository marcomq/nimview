//src/components/Navbar.vue
<template>
  <div>
    <b-navbar toggleable="lg" type="dark" variant="success">
      <b-container>
          <b-navbar-brand href="#">Application</b-navbar-brand>
          <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>
          <b-collapse id="nav-collapse" is-nav>
            <!-- Right aligned nav items -->
            <b-navbar-nav class="ml-auto">
              
              <b-nav-item-dropdown right>
                <!-- Using 'button-content' slot -->
                <template slot="button-content"><em>Nothing here yet</em></template>
                <b-dropdown-item href="#">Some Action</b-dropdown-item>
                
              </b-nav-item-dropdown>
            </b-navbar-nav>
          </b-collapse>
        </b-container>
    </b-navbar>
  </div>  
</template>